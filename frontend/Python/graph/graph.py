# ===- graph.py ----------------------------------------------------------------
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ===---------------------------------------------------------------------------
#
# This is the graph level of the FTM Compiler frontend.
#
# ===---------------------------------------------------------------------------

from typing import Any, List, Optional
from types import FunctionType
from enum import Enum, auto
import ctypes
import functools
import logging
import numpy as np

import mlir.ir as ir
import mlir.dialects.func as func
from mlir.passmanager import *
from mlir.execution_engine import *
from mlir import runtime as rt

from .operation import *
from .type import *

logger = logging.getLogger(__name__)


def make_output_memref_descriptor(ranks, dtypes):
    """
    Make an output memref descriptor for the given memref ranks and dtypes.
    """
    memref_descriptor = []
    for i, (rank, dtype) in enumerate(zip(ranks, dtypes)):
        memref_descriptor.append(
            (str(i), rt.make_nd_memref_descriptor(rank, dtype))
        )

    class OutputDescriptor(ctypes.Structure):
        """Builds an output struct descriptor for the multi memref."""

        _fields_ = memref_descriptor

    return OutputDescriptor


class NodeType(Enum):
    FakeNode = auto()
    InputNode = auto()
    OtherNode = auto()


class Graph:
    """
    Graph is a graph-level expression for the FTM Compiler frontends.
    It acts as a model compute graph, which converts a Graph into an equivalent
    MLIR module.

    Attributes:
    - _body: List[Op]
        The sequence of operation nodes in the graph.
    - _inputs: List[TensorMeta]
        The model inputs represented as TensorMeta objects.
    - _fake_params: List[TensorMeta]
        The fake parameters represented as TensorMeta objects.
    - device: str
        The hardware for graph runtime.
    - _imported_module: Union[None, ImportedModuleType]
        The imported MLIR module after compilation, if set.
    - _ops_registry: dict
        The ops lower strategy for the graph.
    - _func_name: str
        The function name for the MLIR module.
    - _ctx: ir.Context
        The context of the MLIR module.
    - _output_memref: Union[None, ctypes.POINTER]
        The memref pointer in the MLIR function output, if set.
    - _output_descriptor: Union[None, OutputDescriptorType]
        The output descriptor for the MLIR function, if set.
    - ee_: Union[None, ExecutionEngineType]
        The execution engine for the graph, if set.
    """

    def __init__(
        self,
        ops_registry: dict,
        func_name: str,
        device: DeviceType = DeviceType.CPU,
        verbose=False,
        enable_external_calls: bool = False,
    ) -> None:
        self._body = []
        self._inputs = []
        self.node_table: Dict[str, Op] = {}
        self._fake_params = []
        self.device = device
        self._imported_module = None
        self._params_ref = None
        self._verbose = verbose
        self._ops_registry = ops_registry
        self._func_name = func_name
        self._ctx = ir.Context()
        self._output_memref = None
        self._output_descriptor = None
        self.execution_engine = None
        self.op_groups: Dict[str, List[Op]] = {}
        self.group_map_device: Dict[str, DeviceType] = {}
        self._enable_external_calls = enable_external_calls

    @property
    def body(self):
        return self._body

    @body.setter
    def body(self, new_body):
        self._body = new_body

    def add_node(self, node: Op, node_type: NodeType = NodeType.OtherNode):
        node_idx = len(self._body)
        self._body.append(node)
        self.node_table[node.name] = node
        if node_type == NodeType.FakeNode:
            self._fake_params.append(node_idx)
        elif node_type == NodeType.InputNode:
            self._inputs.append(node_idx)

    def get_input(self, i):
        return self._body[self._inputs[i]]

    @property
    def inputs(self) -> list[Op]:
        return [self.get_input(i) for i in range(len(self._inputs))]

    @property
    def inputs_shapes(self) -> list[TensorMeta]:
        tm_list = []
        for input in self.inputs:
            input_tm_dict = input.tensor_meta
            if isinstance(input_tm_dict, TensorMeta):
                tm_list.append(input_tm_dict)
                continue
            tm_list.append(
                TensorMeta(
                    shape=input_tm_dict["shape"],
                    dtype=input_tm_dict["dtype"],
                )
            )
        return tm_list

    def get_fake_params(self, i):
        return self._body[self._fake_params[i]]

    @property
    def params(self) -> list[Op]:
        return [self.get_fake_params(i) for i in range(len(self._fake_params))]

    @property
    def params_shapes(self) -> list[TensorMeta]:
        tm_list = []
        for param in self.params:
            param_tm_dict = param.tensor_meta
            if isinstance(param_tm_dict, TensorMeta):
                tm_list.append(param_tm_dict)
                continue
            tm_list.append(
                TensorMeta(
                    shape=param_tm_dict["shape"],
                    dtype=param_tm_dict["dtype"],
                )
            )
        return tm_list

    def check_delete_node(self, node: Op) -> bool:
        if not (node.name in self.node_table):
            raise KeyError("node{0} not in graph".format(node.name))
        if len(node._children) == 0:
            return True
        return False

    def delete_node(self, node: Op, parents: List[Op]):
        node_idx = self._body.index(node)

        if node_idx in self._inputs:
            self._inputs.remove(node_idx)

        for i, ref_idx in enumerate(self._inputs):
            if ref_idx > node_idx:
                self._inputs[i] -= 1

        if node_idx in self._fake_params:
            self._fake_params.remove(node_idx)

        for i, ref_idx in enumerate(self._fake_params):
            if ref_idx > node_idx:
                self._fake_params[i] -= 1

        for i in parents:
            i._children.remove(node.name)
        node.args.clear()
        node.kwargs.clear()
        node._children.clear()
        self._body.remove(node)
        self.node_table.pop(node.name)

    def displace_node(self, node: Op, newnode: Op):
        newnode._arguments = node.args
        newnode._keyword_arguments = node.kwargs
        newnode._tensor_meta = node.tensor_meta
        newnode._op_type = node._op_type

        for i in node._children:
            newnode.add_children(i)
        users = [self.node_table[i] for i in node._children]
        for user in users:
            if node.name in user._parents:
                user._parents[user._parents.index(node.name)] = newnode.name
            user.args[user.args.index(node.name)] = newnode.name
        node._children.clear()
        for i in node._parents:
            newnode.add_parent(i)
        parents = [self.node_table[i] for i in node._parents]
        for parent in parents:
            parent._children[parent._children.index(node.name)] = newnode.name
        node._parents.clear()
        self._body[self._body.index(node)] = newnode
        self.node_table.pop(node.name)
        self.node_table[newnode.name] = newnode

    def displace_node_with_chain(self, node: Op, chain: list[Op]):
        chain[0]._arguments = node.args
        chain[0]._keyword_arguments = node.kwargs

        for i in node._parents:
            chain[0].add_parent(i)
        parents = [self.node_table[i] for i in node._parents]
        for parent in parents:
            parent._children[parent._children.index(node.name)] = chain[0].name
        node._parents.clear()

        chain[-1].tensor_meta = node.tensor_meta

        for i in node._children:
            chain[-1].add_children(i)
        users = [self.node_table[i] for i in node._children]
        for user in users:
            if node.name in user._parents:
                user._parents[user._parents.index(node.name)] = chain[-1].name
            user.args[user.args.index(node.name)] = chain[-1].name
        node._children.clear()

        node_idx = self._body.index(node)
        self._body = self.body[:node_idx] + chain + self.body[node_idx + 1 :]

    def replace_as_child(
        self, parent_ops: list[Op] | Op, child_op: Op, new_op: Op
    ):
        if not isinstance(parent_ops, list):
            parent_ops = [parent_ops]

        child_name = child_op._name
        new_child_name = new_op._name

        for parent_name in parent_ops:
            parent_op = self.node_table[parent_name]
            parent_op._children[parent_op._children.index(child_name)] = (
                new_child_name
            )

    def replace_as_parent(
        self, parent_op: Op, child_ops: list[Op] | Op, new_op: Op
    ):
        if not isinstance(child_ops, list):
            child_ops = [child_ops]

        parent_name = parent_op._name
        new_parent_name = new_op._name

        for child_name in child_ops:
            child_op = self.node_table[child_name]

            if parent_name in child_op._parents:
                child_op._parents[child_op._parents.index(parent_name)] = (
                    new_parent_name
                )

            if parent_name in child_op._arguments:
                child_op._arguments[child_op._arguments.index(parent_name)] = (
                    new_parent_name
                )

    def init_op_group(self):
        for i, op in enumerate(self._body):
            if isinstance(op, PlaceholderOp) or isinstance(op, OutputOp):
                continue
            group = [op]
            subgraph_name = "subgraph{}".format(i)
            self.group_map_device[subgraph_name] = DeviceType.CPU
            self.op_groups[subgraph_name] = group

    def fuse_ops(self, pattern_list: List[FunctionType]):
        for pattern_func in pattern_list:
            pattern_func(self)

    def perform(self, func_list: List[FunctionType]):
        for transform_func in func_list:
            transform_func(self)

    def lower_to_top_level_ir(self):
        """
        Lowers the graph to top-level MLIR dialects (TOSA/Linalg/Math/Arith).
        """
        with ir.Location.unknown(self._ctx):
            fx_importer = GraphImporter(
                self._body,
                self.params_shapes,
                self.inputs_shapes,
                self._func_name,
                self._ops_registry,
                False,
                self.device,
                verbose=self._verbose,
                enable_external_calls=self._enable_external_calls,
            )
            self._imported_module = fx_importer.import_graph()
            outputs = fx_importer.get_output_nodes()
        self._output_memref = []
        output_ranks = []
        output_dtypes = []
        for out_node in outputs:
            out_type = ir.RankedTensorType(out_node.type)
            shape = list(out_type.shape)
            dtype = out_type.element_type
            match str(dtype):
                case "i1":
                    np_type = np.dtype(np.bool_)
                case "i8":
                    np_type = np.dtype(np.int8)
                case "i32":
                    np_type = np.dtype(np.int32)
                case "i64":
                    np_type = np.dtype(np.int64)
                case "f16":
                    np_type = np.dtype(np.float16)
                case "bf16":
                    np_type = np.dtype(np.uint16)
                case "f32":
                    np_type = np.dtype(np.float32)
                case "f64":
                    np_type = np.dtype(np.float64)
                case "complex<f32>":
                    np_type = np.dtype(np.complex64)
                case "complex<f64>":
                    np_type = np.dtype(np.complex128)
                case _:
                    raise NotImplementedError(f"Unsupported dtype {dtype}")
            self._output_memref.append(
                ctypes.pointer(
                    ctypes.pointer(
                        rt.make_nd_memref_descriptor(
                            len(shape), rt.as_ctype(np_type)
                        )()
                    )
                )
            )
            output_ranks.append(len(shape))
            output_dtypes.append(rt.as_ctype(np_type))
        self._output_descriptor = make_output_memref_descriptor(
            output_ranks, output_dtypes
        )

    def lower_to_linalg_ir(self):
        """
        Lower graph to Linalg IR (suitable as input for ftm-opt --ftm-pipeline).
        Performs TOSA -> Linalg/Tensor/Arith lowering only.
        """
        if self._imported_module is None:
            self.lower_to_top_level_ir()

        with ir.Location.unknown(self._ctx):
            pm = PassManager("builtin.module")
            pm.add("func.func(tosa-to-linalg-named)")
            pm.add("func.func(tosa-to-linalg)")
            pm.add("func.func(tosa-to-tensor)")
            pm.add("func.func(tosa-to-arith)")
            pm.run(self._imported_module.operation)

    def lower_to_llvm_ir(self):
        """
        Lower graph to LLVM IR (for JIT execution via ExecutionEngine).
        """
        if self._imported_module is None:
            self.lower_to_top_level_ir()

        with ir.Location.unknown(self._ctx):
            pm = PassManager("builtin.module")
            pm.add("func.func(tosa-to-linalg-named)")
            pm.add("func.func(tosa-to-linalg)")
            pm.add("func.func(tosa-to-tensor)")
            pm.add("func.func(tosa-to-arith)")
            pm.run(self._imported_module.operation)
            pm2 = PassManager("builtin.module")
            pm2.add("arith-expand")
            pm2.add("eliminate-empty-tensors")
            pm2.add("empty-tensor-to-alloc-tensor")
            pm2.add("convert-elementwise-to-linalg")
            pm2.add("one-shot-bufferize{bufferize-function-boundaries}")
            pm2.add("func.func(linalg-generalize-named-ops)")
            pm2.add("func.func(convert-linalg-to-loops)")
            pm2.add("affine-loop-fusion")
            pm2.add("func.func(affine-parallelize)")
            pm2.add("convert-scf-to-openmp")
            pm2.add("expand-strided-metadata")
            pm2.add("lower-affine")
            pm2.add("convert-vector-to-llvm")
            pm2.add("memref-expand")
            pm2.add("arith-expand")
            pm2.add("convert-complex-to-llvm")
            pm2.add("convert-arith-to-llvm")
            pm2.add("finalize-memref-to-llvm")
            pm2.add("convert-scf-to-cf")
            pm2.add("convert-cf-to-llvm")
            pm2.add("func.func(llvm-request-c-wrappers)")
            pm2.add("convert-openmp-to-llvm")
            pm2.add("convert-math-to-llvm")
            pm2.add("convert-math-to-libm")
            pm2.add("convert-func-to-llvm")
            pm2.add("reconcile-unrealized-casts")
            pm2.run(self._imported_module.operation)

    def compile(self):
        """
        Compile graph from Graph to LLVM IR.
        """
        self.lower_to_top_level_ir()
        self.lower_to_llvm_ir()

    def get_mlir_module(self) -> ir.Module:
        """
        Return the imported MLIR module (after any lowering).
        """
        return self._imported_module


class GraphImporter:
    """
    Imports a graph and generates an MLIR module in high-level dialects.

    Attributes:
        _symbol_table (dict): A dictionary to keep track of the symbols.
        _body (List[Op]): The graph module to be imported.
        _func_name (str): Name of the generated MLIR function.
        _inputs (List[TensorMeta]): Input tensor(s) of the graph.
        _num_input_visited (int): Number of input nodes that have been visited.
        _module (mlir.ir.Module): The generated MLIR module.
        _ops_registry (dict): Registry for the candidate operations.
    """

    def __init__(
        self,
        body: List[Op],
        params_shapes: List[TensorMeta],
        inputs_shapes: List[TensorMeta],
        func_name: str,
        ops_registry: dict,
        do_param_pack: bool = False,
        device: DeviceType = DeviceType.CPU,
        verbose=False,
        enable_external_calls: bool = False,
    ):
        if ops_registry is None:
            ops_registry = {}
        self._symbol_table = {}
        self._body = body
        self._device = device
        self._func_name = func_name
        self._params_shapes = params_shapes
        self._inputs_shapes = inputs_shapes
        self._verbose = verbose
        self._do_param_pack = do_param_pack
        self._param_packs = []
        self._num_input_visited = 0
        self._module = ir.Module.create()
        self._ops_registry = ops_registry
        self._current_param_pack_offset = None
        self._enable_external_calls = enable_external_calls

    def _str_to_mlir_dtype(self, dtype: str) -> ir.Type:
        match dtype:
            case TensorDType.Int8:
                return ir.IntegerType.get_signless(8)
            case TensorDType.Int32:
                return ir.IntegerType.get_signless(32)
            case TensorDType.Int64:
                return ir.IntegerType.get_signless(64)
            case TensorDType.Float16:
                return ir.F16Type.get()
            case TensorDType.BFloat16:
                return ir.BF16Type.get()
            case TensorDType.Float32:
                return ir.F32Type.get()
            case TensorDType.Float64:
                return ir.F64Type.get()
            case TensorDType.Bool:
                return ir.IntegerType.get_signless(1)
            case TensorDType.Complex64:
                return ir.ComplexType.get(ir.F32Type.get())
            case TensorDType.Complex128:
                return ir.ComplexType.get(ir.F64Type.get())
            case _:
                raise NotImplementedError(f"Unsupported dtype {dtype}")

    def _pack_params(self) -> None:
        dtypes = list(set([param.dtype for param in self._params_shapes]))
        dtypes.sort(key=str)
        self._current_param_pack_offset = {dtype: 0 for dtype in dtypes}
        for dtype in dtypes:
            params_of_dtype = [
                param for param in self._params_shapes if param.dtype == dtype
            ]
            param_total_size = 0
            for param in params_of_dtype:
                param_total_size += functools.reduce(
                    lambda x, y: x * y, list(param.shape), 1
                )
            mlir_dtype = self._str_to_mlir_dtype(dtype)
            self._param_packs.append(
                ir.MemRefType.get([param_total_size], mlir_dtype)
            )

    def import_graph(self) -> ir.Module:
        """
        Imports graph and generates an MLIR module in high-level dialects.
        """
        if self._do_param_pack:
            raise ValueError("import_graph does not support do_param_pack=True; use import_main_graph()")
        with ir.InsertionPoint(self._module.body):
            arguments = []
            inputs = self._params_shapes + self._inputs_shapes
            for arg in inputs:
                shape_list = list(arg.shape)
                dtype = arg.dtype
                mlir_dtype = self._str_to_mlir_dtype(dtype)
                tensor_arg = ir.RankedTensorType.get(shape_list, mlir_dtype)
                arguments.append(tensor_arg)
            extern_func = []
            for node in self._body:
                if isinstance(node, FuncOp):
                    extern_func.append(node)
                    self._import_op(node)

            @func.FuncOp.from_py_func(*arguments, name=self._func_name)
            def generated_func(*args):
                args_list = list(args)
                func_op = self._module.body.operations[0]
                for node in self._body:
                    if node in extern_func:
                        continue
                    old_ops = [op for op in func_op.body.blocks[0].operations]
                    if isinstance(node, OutputOp):
                        output_node_args = node.args
                        returns = [
                            self._symbol_table.get((str(output_arg), 0))
                            for output_arg in output_node_args
                        ]
                        self._symbol_table[("output", 0)] = returns
                    elif isinstance(node, PlaceholderOp):
                        self._import_placeholder(node, args_list)
                    elif isinstance(node, GetItemOp):
                        self._symbol_table[(str(node.name), 0)] = (
                            self._symbol_table[
                                (str(node.args[0]), node.args[1])
                            ]
                        )
                    else:
                        self._import_op(node)
                    new_ops = [op for op in func_op.body.blocks[0].operations]
                    if self._verbose:
                        logger.debug("=" * 20 + "Graph Node" + "=" * 20)
                        logger.debug("Node: " + node.name)
                        logger.debug("Type: " + str(node._op_type))
                        logger.debug("Arguments: " + str(node.args))
                        logger.debug("Parents: " + str(node._parents))
                        logger.debug("Children: " + str(node._children))
                        logger.debug("-" * 20 + "MLIR OPS" + "-" * 20)
                        for op in new_ops:
                            if op not in old_ops:
                                logger.debug(str(op))
                        logger.debug("")

                return self._symbol_table.get(("output", 0))

            # Generate external function declarations for CallExternalOp nodes
            if self._enable_external_calls:
                from .operation import CallExternalOp

                for node in self._body:
                    if isinstance(node, CallExternalOp):
                        self._generate_external_func_decl(node)

        return self._module

    def import_main_graph(self) -> ir.Module:
        """
        Imports main graph to organize all subgraphs and generates an MLIR
        module in high-level dialects with memref.
        """
        with ir.InsertionPoint(self._module.body):
            arguments = []
            if self._do_param_pack:
                self._pack_params()
                arguments.extend(self._param_packs)
                inputs = self._inputs_shapes
            else:
                inputs = self._params_shapes + self._inputs_shapes
            for arg in inputs:
                shape_list = list(arg.shape)
                dtype = arg.dtype
                mlir_dtype = self._str_to_mlir_dtype(dtype)
                tensor_arg = ir.MemRefType.get(shape_list, mlir_dtype)
                arguments.append(tensor_arg)
            extern_func = []
            for node in self._body:
                if isinstance(node, FuncOp):
                    extern_func.append(node)
                    self._import_op(node)

            @func.FuncOp.from_py_func(*arguments, name=self._func_name)
            def generated_func(*args):
                args_list = list(args)
                for node in self._body:
                    if node in extern_func:
                        continue
                    if isinstance(node, OutputOp):
                        output_node_args = node.args
                        returns = [
                            self._symbol_table.get((str(output_arg), 0))
                            for output_arg in output_node_args
                        ]
                        self._symbol_table[("output", 0)] = returns
                    elif isinstance(node, PlaceholderOp):
                        self._import_placeholder(node, args_list)
                    elif isinstance(node, GetItemOp):
                        self._symbol_table[(str(node.name), 0)] = (
                            self._symbol_table[
                                (str(node.args[0]), node.args[1])
                            ]
                        )
                    else:
                        self._import_op(node)

                return self._symbol_table.get(("output", 0))

        return self._module

    def _import_placeholder(
        self, node: PlaceholderOp, args_list: List[ir.BlockArgument]
    ):
        if (
            self._num_input_visited < len(self._params_shapes)
            and self._do_param_pack
        ):
            dtype = node.tensor_meta["dtype"]
            pack_of_dtype = None
            for pack in args_list:
                if ir.MemRefType(
                    pack.type
                ).element_type == self._str_to_mlir_dtype(dtype):
                    pack_of_dtype = pack
                    break
            placeholder_name = self._ops_registry["param.extract"](
                node, self._current_param_pack_offset[dtype], pack_of_dtype
            ).result
            self._current_param_pack_offset[dtype] += functools.reduce(
                lambda x, y: x * y, list(node.tensor_meta["shape"]), 1
            )
        elif self._do_param_pack:
            if len(self._params_shapes) > 0:
                placeholder_name = args_list[
                    self._num_input_visited
                    - len(self._params_shapes)
                    + len(self._param_packs)
                ]
            else:
                placeholder_name = args_list[self._num_input_visited]
        else:
            placeholder_name = args_list[self._num_input_visited]

        self._symbol_table[(str(node.name), 0)] = placeholder_name
        self._num_input_visited += 1

    def _generate_external_func_decl(self, call_node):
        """
        Generate external function declaration for CallExternalOp.
        """
        from .operation import CallExternalOp
        from ..ops.utils import mlir_element_type_get

        if not isinstance(call_node, CallExternalOp):
            return

        func_name = call_node.call_func_name

        arg_types = []
        for i, arg in enumerate(call_node.args):
            arg_node = None
            for node in self._body:
                if node.name == arg:
                    arg_node = node
                    break

            if arg_node and hasattr(arg_node, "tensor_meta"):
                if isinstance(arg_node.tensor_meta, dict):
                    shape = arg_node.tensor_meta.get("shape", [])
                    dtype = arg_node.tensor_meta.get("dtype", "float32")
                else:
                    shape = arg_node.tensor_meta.shape
                    dtype = arg_node.tensor_meta.dtype
                mlir_dtype = mlir_element_type_get(dtype)
                arg_types.append(
                    ir.RankedTensorType.get(list(shape), mlir_dtype)
                )

        result_types = []
        if (
            hasattr(call_node, "tensor_meta")
            and "shape" in call_node.tensor_meta
        ):
            shape = call_node.tensor_meta["shape"]
            dtype = call_node.tensor_meta["dtype"]

            if (
                isinstance(shape, (list, tuple))
                and len(shape) > 0
                and isinstance(shape[0], (list, tuple))
            ):
                for i, s in enumerate(shape):
                    mlir_dtype = mlir_element_type_get(dtype[i])
                    result_types.append(ir.RankedTensorType.get(s, mlir_dtype))
            else:
                mlir_dtype = mlir_element_type_get(dtype)
                result_types.append(
                    ir.RankedTensorType.get(list(shape), mlir_dtype)
                )

        function_type = ir.FunctionType.get(
            inputs=arg_types, results=result_types
        )

        with ir.InsertionPoint(self._module.body):
            func_decl = func.FuncOp(
                name=func_name, type=function_type, visibility="private"
            )
            func_decl.attributes["llvm.emit_c_interface"] = ir.UnitAttr.get()

    def _import_op(self, node: Op):
        op_name = node.__class__.__name__
        op_ret: ir.Operation | ir.Value | tuple | List | ir.OpResult = (
            self._ops_registry[op_name](node, self._symbol_table)
        )
        if isinstance(op_ret, tuple | List | ir.OpResultList):
            for i, operation in enumerate(op_ret):
                if isinstance(operation, ir.Operation) or isinstance(
                    operation, ir.OpView
                ):
                    self._symbol_table[(str(node.name), i)] = operation.result
                elif isinstance(operation, ir.OpResult):
                    self._symbol_table[(str(node.name), i)] = operation
                else:
                    raise NotImplementedError
        elif isinstance(op_ret, ir.OpResult):
            self._symbol_table[(str(node.name), 0)] = op_ret
        elif isinstance(op_ret, ir.BlockArgument):
            self._symbol_table[(str(node.name), 0)] = op_ret
        else:
            for i, result in enumerate(op_ret.results):
                self._symbol_table[(str(node.name), i)] = result

    def get_output_nodes(self):
        """
        Get output nodes from the lowered mlir func.
        """
        return self._symbol_table.get(("output", 0))
