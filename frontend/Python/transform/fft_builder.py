"""Lower AlgorithmBuilder recordings to MLIR.

This module now inspects `builder.ops` and emits structured MLIR using the
Python MLIR bindings when `mode == "bindings"`. For text mode we defer to
the existing textual generator in `ops.fft`.

The current implementation supports a small set of builder primitives:
- dft
- twiddle_mul
- butterfly
- permute
- reshape (no-op)
- stockham_stage
- stockham_fft (expands to multiple stages)
"""
from typing import Optional


def build_mlir_from_builder(builder, N: int, name: Optional[str] = None, mode: str = "text") -> str:
    # Only bindings mode is supported now (textual generator removed).
    if mode != "bindings":
        raise ValueError("Only 'bindings' mode is supported for FFT lowering; textual generator removed")

    # Bindings lowering: construct a Module and Func and lower each recorded op.
    import math
    import mlir.ir as ir
    from mlir.dialects import func, memref, arith

    ctx = ir.Context()
    with ir.Location.unknown(ctx):
        module = ir.Module.create()

        f32 = ir.F32Type.get()
        idx = ir.IndexType.get()
        # support N as int or iterable shape
        if isinstance(N, int):
            shape = [N]
        else:
            shape = list(N)
        totalN = 1
        for d in shape:
            totalN *= d
        in_type = memref.MemRefType.get(shape, f32)
        out_type = memref.MemRefType.get(shape, f32)
        func_type = ir.FunctionType.get(inputs=[in_type, in_type, out_type, out_type], results=[])

        with ir.InsertionPoint(module.body):
            fname = name or f"fft_builder_{totalN}"
            fop = func.FuncOp(name=fname, type=func_type, visibility="private")
            fop.add_entry_block()
            with ir.InsertionPoint(fop.entry_block):
                # pre-create index constants for ND shapes
                def make_c_idx(totalN, shape):
                    # compute stride for each dim: product of dims after it
                    strides = []
                    for i in range(len(shape)):
                        s = 1
                        for j in range(i + 1, len(shape)):
                            s *= shape[j]
                        strides.append(s)
                    res = []
                    for t in range(totalN):
                        coords = []
                        for i, dim in enumerate(shape):
                            stride = strides[i]
                            coord = (t // stride) % dim if stride != 0 else (t % dim)
                            coords.append(arith.ConstantOp(idx, int(coord)).result)
                        if len(coords) == 1:
                            res.append(coords[0])
                        else:
                            res.append(coords)
                    return res

                c_idx = make_c_idx(totalN, shape)#似乎多余

                # symbol table: map builder symbol -> pair of memref Values (real, imag)
                symtab = {}

                # map the default input symbol to the function arguments (real, imag)
                symtab["input"] = (fop.entry_block.arguments[0], fop.entry_block.arguments[1])
                # map the default output symbol to the function outputs
                symtab["output"] = (fop.entry_block.arguments[2], fop.entry_block.arguments[3])

                def ensure_buffer(name: str):
                    """Ensure a named temp buffer (real, imag) exists in symtab.

                    Returns tuple (real_memref, imag_memref).
                    """
                    if name in symtab:
                        return symtab[name]

                    # If the builder registered this name as an input/output,
                    # map it to the function arguments instead of allocating.
                    if hasattr(builder, "registered_buffers") and name in builder.registered_buffers:
                        role = builder.registered_buffers[name]
                        if role == "input":
                            symtab[name] = (fop.entry_block.arguments[0], fop.entry_block.arguments[1])
                            return symtab[name]
                        if role == "output":
                            symtab[name] = (fop.entry_block.arguments[2], fop.entry_block.arguments[3])
                            return symtab[name]
                    # allocate temporary memrefs
                    alloc_r = memref.AllocOp(memref.MemRefType.get(shape, f32), [], []).result
                    alloc_i = memref.AllocOp(memref.MemRefType.get(shape, f32), [], []).result
                    symtab[name] = (alloc_r, alloc_i)
                    return symtab[name]

                # Import lowering helpers from ops.fft
                from ..ops.fft import (
                    gen_dft_mlir_bindings,
                    lower_dft_into,
                    lower_twiddle_mul,
                    lower_butterfly,
                    lower_permute,
                    lower_reshape,
                    lower_stockham_stage,
                    lower_stockham_fft,
                )

                # Lower recorded ops sequentially
                for op in builder.ops:
                    if not op:
                        continue
                    opname = op[0]

                    if opname == "dft":
                        # lowering-time DFT into the current function body
                        # op format: ("dft", input_name, axis)
                        _, in_name, axis = op
                        in_r, in_i = ensure_buffer(in_name)
                        out_r, out_i = ensure_buffer("output")
                        lower_dft_into(in_r, in_i, out_r, out_i, shape, axis, f32, arith, memref, idx)

                    if opname == "twiddle_mul":
                        # ("twiddle_mul", in, out, N1, N2, axis)
                        _, in_name, out_name, N1, N2, axis = op
                        in_r, in_i = ensure_buffer(in_name)
                        out_r, out_i = ensure_buffer(out_name)
                        lower_twiddle_mul(in_r, in_i, out_r, out_i, shape, axis, N1, N2, f32, arith, memref, idx)

                    elif opname == "butterfly":
                        # ("butterfly", a, b, w, out1, out2, axis)
                        _, a_name, b_name, w_name, out1_name, out2_name, axis = op
                        a_r, a_i = ensure_buffer(a_name)
                        b_r, b_i = ensure_buffer(b_name)
                        w_r, w_i = ensure_buffer(w_name)
                        out1_r, out1_i = ensure_buffer(out1_name)
                        out2_r, out2_i = ensure_buffer(out2_name)
                        lower_butterfly(a_r, a_i, b_r, b_i, w_r, w_i, out1_r, out1_i, out2_r, out2_i, shape, axis, arith, memref, idx)

                    elif opname == "permute":
                        # ("permute", in, out, pattern, axis)
                        _, in_name, out_name, pattern, axis = op
                        in_r, in_i = ensure_buffer(in_name)
                        out_r, out_i = ensure_buffer(out_name)
                        lower_permute(in_r, in_i, out_r, out_i, pattern, shape, axis, arith, memref, idx)

                    elif opname == "reshape":
                        # 当前实现中 reshape 是一个 no-op，主要作为一个 hint 来指导后续的优化或代码生成阶段。
                        # ("reshape", in, out, new_shape, axis)
                        _, in_name, out_name, new_shape, axis = op
                        in_r, in_i = ensure_buffer(in_name)
                        out_r, out_i = ensure_buffer(out_name)
                        lower_reshape(in_r, in_i, out_r, out_i, tuple(new_shape), axis, arith, memref, idx)

                    elif opname == "stockham_stage":
                        # ("stockham_stage", in, out, stage, axis)
                        _, in_name, out_name, stage, axis = op
                        in_r, in_i = ensure_buffer(in_name)
                        out_r, out_i = ensure_buffer(out_name)
                        lower_stockham_stage(in_r, in_i, out_r, out_i, shape, axis, stage, f32, arith, memref, idx)

                    elif opname == "stockham_fft":
                        # ("stockham_fft", in, out, axis)
                        _, in_name, out_name, axis = op
                        # expand into stages by inserting stockham_stage ops after current op
                        # use helper that inserts ops; pass a small lambda that inserts right after
                        # When inserting multiple staged ops we must ensure they appear
                        # in the correct execution order. Use a small closure that
                        # tracks how many inserts we've done so subsequent inserts
                        # are placed after earlier ones.
                        inserted = [0] # inserted[0]: track how many stages we've inserted so far
                        def insert_after(x):
                            idx = builder.ops.index(op) + 1 + inserted[0]
                            builder.ops.insert(idx, x)
                            inserted[0] += 1

                        # pass shape so the FFT expansion can insert stages that end in the output
                        lower_stockham_fft(in_name, out_name, shape, axis, symtab, insert_after, f32, arith, memref, idx)

                    else:
                        # unknown op: ignore or could raise
                        # for now, skip
                        pass

                # At end of function ensure results are in the function outputs.
                # If user wrote into a buffer named "output", we've already used
                # the function's output memrefs. Otherwise, if some other buffer
                # name maps to a temp, copy it back to the outputs.
                outbuf_r, outbuf_i = symtab["output"]
                # If they are the same as function outputs, nothing to do
                if outbuf_r is not fop.entry_block.arguments[2] or outbuf_i is not fop.entry_block.arguments[3]:
                    # copy elementwise over ND shape
                    # create nested loops over each dim using index constants
                    # simpler approach: iterate over total number and create coords
                    totalN = 1
                    for d in shape:
                        totalN *= d
                    for t in range(totalN):
                        # compute coords
                        coords = []
                        rem = t
                        for i, dim in enumerate(shape):
                            stride = 1
                            for j in range(i + 1, len(shape)):
                                stride *= shape[j]
                            coord = (rem // stride) % dim if stride != 0 else (rem % dim)
                            coords.append(arith.ConstantOp(idx, int(coord)).result)
                        v_r = memref.LoadOp(outbuf_r, coords).result
                        v_i = memref.LoadOp(outbuf_i, coords).result
                        memref.StoreOp(v_r, fop.entry_block.arguments[2], coords)
                        memref.StoreOp(v_i, fop.entry_block.arguments[3], coords)

                func.ReturnOp([])
    # return module text
    return str(module)
