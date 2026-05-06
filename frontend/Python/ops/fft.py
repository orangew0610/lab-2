"""Simple FFT/DFT MLIR generator (prototype)

This module provides a minimal DFT generator that emits MLIR text for a
small fixed-size transform (N = 4/8/16...). It is a frontend prototype to
help validate the pipeline end-to-end. The generated function uses two
real-valued memrefs (real and imag parts) as input and produces two
real-valued memrefs as output (real and imag parts of the result).

Notes:
- This is a straightforward DFT implementation (O(N^2)) unrolled for the
  given N. It is not optimized; it's intended as a clear, small demo so
  you can later replace the generator with an FFT decomposition.
- The output is MLIR textual module (string). The project already contains
  MLIR parsing facilities in midend; the frontend will hand this string to
  the pipeline.
"""
from typing import List
import math


def gen_dft_mlir_bindings(N: int, name: str = None) -> str:
    """Generate the DFT MLIR using Python MLIR bindings.

    This replaces the old textual generator. Returns the module string.
    """
    import math
    import mlir.ir as ir
    from mlir.dialects import func, memref, arith

    # Create a fresh context and module and build ops inside
    ctx = ir.Context()
    with ir.Location.unknown(ctx):
        module = ir.Module.create()
        # Prepare types
        f32 = ir.F32Type.get()
        idx = ir.IndexType.get()
        # support N as int or an iterable shape
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
            fname = name or f"fft_dft_{N}"
            fop = func.FuncOp(name=fname, type=func_type)#, visibility="private"
            fop.add_entry_block()
            # insert into function body
            with ir.InsertionPoint(fop.entry_block):
                # create index constants for each coordinate of the (possibly) multi-dim shape
                # c_idx[t] will be either an Index value (for 1D) or a list of Index values (for ND)
                def make_c_idx(totalN, shape):
                    # compute strides for each dimension
                    strides = []
                    prod = 1
                    for s in shape[1:]:
                        prod *= s
                        strides.append(prod)
                    # adjust strides to match dims: for dims [d0,d1,...], stride for dim0 is prod(d1..)
                    strides = [int(prod) for prod in ([int(__import__('functools').reduce(lambda a,b: a*b, shape[i+1:], 1) if i+1 < len(shape) else 1) for i in range(len(shape))])]
                    res = []
                    for t in range(totalN):
                        coords = []
                        rem = t
                        for i, dim in enumerate(shape):
                            stride = strides[i]
                            coord = (t // stride) % dim if stride != 0 else (t % dim)
                            coords.append(arith.ConstantOp(idx, int(coord)).result)
                        if len(coords) == 1:
                            res.append(coords[0])
                        else:
                            res.append(coords)
                    return res

                c_idx = make_c_idx(totalN, shape)

                # accumulators and computation
                for k in range(totalN):
                    acc_r = arith.ConstantOp(f32, 0.0).result
                    acc_i = arith.ConstantOp(f32, 0.0).result
                    # unrolled sum
                    for n in range(totalN):
                        angle = -2.0 * math.pi * k * n / float(totalN)
                        cos_val = math.cos(angle)
                        sin_val = math.sin(angle)
                        cos_c = arith.ConstantOp(f32, cos_val).result
                        sin_c = arith.ConstantOp(f32, sin_val).result

                        # memref.LoadOp expects a list of index operands; c_idx[n] may be a list or a single value
                        idx_operand = c_idx[n] if isinstance(c_idx[n], list) else [c_idx[n]]
                        inr = memref.LoadOp(fop.entry_block.arguments[0], idx_operand).result
                        ini = memref.LoadOp(fop.entry_block.arguments[1], idx_operand).result

                        t1 = arith.MulFOp(inr, cos_c).result
                        t2 = arith.MulFOp(ini, sin_c).result
                        temp_r = arith.SubFOp(t1, t2).result

                        t3 = arith.MulFOp(inr, sin_c).result
                        t4 = arith.MulFOp(ini, cos_c).result
                        temp_i = arith.AddFOp(t3, t4).result

                        acc_r = arith.AddFOp(acc_r, temp_r).result
                        acc_i = arith.AddFOp(acc_i, temp_i).result

                    idx_operand_k = c_idx[k] if isinstance(c_idx[k], list) else [c_idx[k]]
                    memref.StoreOp(acc_r, fop.entry_block.arguments[2], idx_operand_k)
                    memref.StoreOp(acc_i, fop.entry_block.arguments[3], idx_operand_k)

                # return (no operands)
                func.ReturnOp([])

    return str(module)


# Helpers for bindings lowering used by fft_builder. These accept values/types
# produced by the MLIR insertion context and will emit ops into the current
# insertion point.
def lower_complex_mul(a_re, a_im, b_re, b_im, arith):
    t1 = arith.MulFOp(a_re, b_re).result
    t2 = arith.MulFOp(a_im, b_im).result
    r = arith.SubFOp(t1, t2).result

    t3 = arith.MulFOp(a_re, b_im).result
    t4 = arith.MulFOp(a_im, b_re).result
    i = arith.AddFOp(t3, t4).result
    return r, i


def lower_dft_into(in_r, in_i, out_r, out_i, shape, axis, f32, arith, memref, idx_type):
    """Lower an explicit DFT into the current insertion point along `axis`.

    This helper emits elementwise DFT computation for each coordinate along
    the provided axis while keeping other dimensions fixed.
    """
    # If axis is None, perform a full ND DFT (separable across all axes).
    from itertools import product
    dims = len(shape)
    if axis is None:
        ranges = [range(s) for s in shape]
        # iterate over all frequency coordinates k and all input coords n
        for k_coords in product(*ranges):
            acc_r = arith.ConstantOp(f32, 0.0).result
            acc_i = arith.ConstantOp(f32, 0.0).result
            for n_coords in product(*ranges):
                # compute multi-dim separable angle: sum_d (k_d * n_d / shape[d])
                angle_frac = 0.0
                for d in range(dims):
                    angle_frac += (float(k_coords[d]) * float(n_coords[d]) / float(shape[d]))
                angle = -2.0 * math.pi * angle_frac
                cos_val = math.cos(angle)
                sin_val = math.sin(angle)
                cos_c = arith.ConstantOp(f32, cos_val).result
                sin_c = arith.ConstantOp(f32, sin_val).result

                coords = [arith.ConstantOp(idx_type, int(n)).result for n in n_coords]
                inr = memref.LoadOp(in_r, coords).result
                ini = memref.LoadOp(in_i, coords).result

                t1 = arith.MulFOp(inr, cos_c).result
                t2 = arith.MulFOp(ini, sin_c).result
                temp_r = arith.SubFOp(t1, t2).result

                t3 = arith.MulFOp(inr, sin_c).result
                t4 = arith.MulFOp(ini, cos_c).result
                temp_i = arith.AddFOp(t3, t4).result

                acc_r = arith.AddFOp(acc_r, temp_r).result
                acc_i = arith.AddFOp(acc_i, temp_i).result

            # store at k_coords
            coords_k = [arith.ConstantOp(idx_type, int(k)).result for k in k_coords]
            memref.StoreOp(acc_r, out_r, coords_k)
            memref.StoreOp(acc_i, out_i, coords_k)
        return

    # otherwise axis is a single axis index: perform 1D DFT along that axis
    if axis < 0:
        axis = len(shape) + axis
    L = shape[axis]
    axes = [i for i in range(len(shape)) if i != axis]
    if not axes:
        outer_iter = [()]
    else:
        ranges = [range(shape[a]) for a in axes]
        outer_iter = list(product(*ranges))

    for outer in outer_iter:
        for k in range(L):
            acc_r = arith.ConstantOp(f32, 0.0).result
            acc_i = arith.ConstantOp(f32, 0.0).result
            for n in range(L):
                angle = -2.0 * math.pi * k * n / float(L)
                cos_val = math.cos(angle)
                sin_val = math.sin(angle)
                cos_c = arith.ConstantOp(f32, cos_val).result
                sin_c = arith.ConstantOp(f32, sin_val).result

                coords = []
                oi = 0
                for d in range(len(shape)):
                    if d == axis:
                        coords.append(arith.ConstantOp(idx_type, int(n)).result)
                    else:
                        coords.append(arith.ConstantOp(idx_type, int(outer[oi])).result)
                        oi += 1

                inr = memref.LoadOp(in_r, coords).result
                ini = memref.LoadOp(in_i, coords).result

                t1 = arith.MulFOp(inr, cos_c).result
                t2 = arith.MulFOp(ini, sin_c).result
                temp_r = arith.SubFOp(t1, t2).result

                t3 = arith.MulFOp(inr, sin_c).result
                t4 = arith.MulFOp(ini, cos_c).result
                temp_i = arith.AddFOp(t3, t4).result

                acc_r = arith.AddFOp(acc_r, temp_r).result
                acc_i = arith.AddFOp(acc_i, temp_i).result

            # store at k
            coords_k = []
            oi = 0
            for d in range(len(shape)):
                if d == axis:
                    coords_k.append(arith.ConstantOp(idx_type, int(k)).result)
                else:
                    coords_k.append(arith.ConstantOp(idx_type, int(outer[oi])).result)
                    oi += 1
            memref.StoreOp(acc_r, out_r, coords_k)
            memref.StoreOp(acc_i, out_i, coords_k)


def lower_twiddle_mul(in_r, in_i, out_r, out_i, shape, axis, N1, N2, f32, arith, memref, idx_type):
    # Perform twiddle multiplication along `axis` of the ND buffer described by shape.
    # shape: list of dims, axis: axis index (can be negative)
    if axis < 0:
        axis = len(shape) + axis
    L = shape[axis]
    totalN = N1 * N2
    # precompute twiddles for indices along axis
    twiddles = [(math.cos(-2.0 * math.pi * k1 * n2 / float(totalN)), math.sin(-2.0 * math.pi * k1 * n2 / float(totalN)))
                for n2 in range(N2) for k1 in range(N1)]

    # iterate over all coordinates except the axis coordinate
    from itertools import product
    axes = [i for i in range(len(shape)) if i != axis]
    if not axes:
        outer_iter = [()]
    else:
        ranges = [range(shape[a]) for a in axes]
        outer_iter = list(product(*ranges))

    # for each outer coord, apply twiddle per axis index
    for outer in outer_iter:
        for i_axis in range(L):
            # compute flat index into twiddles if needed; for now assume L == len(twiddles)
            tw_idx = i_axis % len(twiddles)
            cos_c = arith.ConstantOp(f32, twiddles[tw_idx][0]).result
            sin_c = arith.ConstantOp(f32, twiddles[tw_idx][1]).result
            # build full coordinate list
            coords = []
            oi = 0
            for d in range(len(shape)):
                if d == axis:
                    coords.append(arith.ConstantOp(idx_type, int(i_axis)).result)
                else:
                    coords.append(arith.ConstantOp(idx_type, int(outer[oi])).result)
                    oi += 1
            a_re = memref.LoadOp(in_r, coords).result
            a_im = memref.LoadOp(in_i, coords).result
            t_re, t_im = lower_complex_mul(a_re, a_im, cos_c, sin_c, arith)
            memref.StoreOp(t_re, out_r, coords)
            memref.StoreOp(t_im, out_i, coords)


def lower_butterfly(a_r, a_i, b_r, b_i, w_r, w_i, out1_r, out1_i, out2_r, out2_i, shape, axis, arith, memref, idx_type):
    # Apply butterfly elementwise along axis
    if axis < 0:
        axis = len(shape) + axis
    L = shape[axis]
    from itertools import product
    axes = [i for i in range(len(shape)) if i != axis]
    if not axes:
        outer_iter = [()]
    else:
        ranges = [range(shape[a]) for a in axes]
        outer_iter = list(product(*ranges))

    for outer in outer_iter:
        for i_axis in range(L):
            coords = []
            oi = 0
            for d in range(len(shape)):
                if d == axis:
                    coords.append(arith.ConstantOp(idx_type, int(i_axis)).result)
                else:
                    coords.append(arith.ConstantOp(idx_type, int(outer[oi])).result)
                    oi += 1
            a_re = memref.LoadOp(a_r, coords).result
            a_im = memref.LoadOp(a_i, coords).result
            b_re = memref.LoadOp(b_r, coords).result
            b_im = memref.LoadOp(b_i, coords).result
            w_re = memref.LoadOp(w_r, coords).result
            w_im = memref.LoadOp(w_i, coords).result

            t_re, t_im = lower_complex_mul(b_re, b_im, w_re, w_im, arith)

            out1_re = arith.AddFOp(a_re, t_re).result
            out1_im = arith.AddFOp(a_im, t_im).result
            out2_re = arith.SubFOp(a_re, t_re).result
            out2_im = arith.SubFOp(a_im, t_im).result

            memref.StoreOp(out1_re, out1_r, coords)
            memref.StoreOp(out1_im, out1_i, coords)
            memref.StoreOp(out2_re, out2_r, coords)
            memref.StoreOp(out2_im, out2_i, coords)


def lower_permute(in_r, in_i, out_r, out_i, pattern, shape, axis, arith, memref, idx_type):
    # Permute indices along axis: pattern is a mapping for indices along axis
    if axis < 0:
        axis = len(shape) + axis
    L = shape[axis]
    from itertools import product
    axes = [i for i in range(len(shape)) if i != axis]
    if not axes:
        outer_iter = [()]
    else:
        ranges = [range(shape[a]) for a in axes]
        outer_iter = list(product(*ranges))

    for outer in outer_iter:
        for src in range(min(L, len(pattern))):
            dst = pattern[src]
            coords_src = []
            coords_dst = []
            oi = 0
            for d in range(len(shape)):
                if d == axis:
                    coords_src.append(arith.ConstantOp(idx_type, int(src)).result)
                    coords_dst.append(arith.ConstantOp(idx_type, int(dst)).result)
                else:
                    coords_src.append(arith.ConstantOp(idx_type, int(outer[oi])).result)
                    coords_dst.append(arith.ConstantOp(idx_type, int(outer[oi])).result)
                    oi += 1
            val_r = memref.LoadOp(in_r, coords_src).result
            val_i = memref.LoadOp(in_i, coords_src).result
            memref.StoreOp(val_r, out_r, coords_dst)
            memref.StoreOp(val_i, out_i, coords_dst)


def lower_reshape(in_r, in_i, out_r, out_i, new_shape, axis, arith, memref, idx_type):
    # Elementwise copy for arbitrary shapes by iterating over new_shape
    from itertools import product
    ranges = [range(s) for s in new_shape]
    for coords in product(*ranges):
        coords_list = [arith.ConstantOp(idx_type, int(c)).result for c in coords]
        v_r = memref.LoadOp(in_r, coords_list).result
        v_i = memref.LoadOp(in_i, coords_list).result
        memref.StoreOp(v_r, out_r, coords_list)
        memref.StoreOp(v_i, out_i, coords_list)


def lower_stockham_stage(in_r, in_i, out_r, out_i, shape, axis, stage, f32, arith, memref, idx_type):
    # Implement a Stockham stage along a specific axis.
    if axis < 0:
        axis = len(shape) + axis
    L = shape[axis]
    block = 1 << stage
    two_block = 2 * block
    tw = []
    for j in range(block):
        angle = -2.0 * math.pi * j / float(2 * block)
        tw.append((math.cos(angle), math.sin(angle)))

    # iterate over outer coordinates
    from itertools import product
    axes = [i for i in range(len(shape)) if i != axis]
    if not axes:
        outer_iter = [()]
    else:
        ranges = [range(shape[a]) for a in axes]
        outer_iter = list(product(*ranges))

    for outer in outer_iter:
        # operate along axis dimension indices using classic iterative radix-2 stage
        for i0 in range(0, L, two_block):
            for j in range(block):
                u_idx = i0 + j
                v_idx = i0 + j + block

                def make_coords(pos):
                    coords = []
                    oi = 0
                    for d in range(len(shape)):
                        if d == axis:
                            coords.append(arith.ConstantOp(idx_type, int(pos)).result)
                        else:
                            coords.append(arith.ConstantOp(idx_type, int(outer[oi])).result)
                            oi += 1
                    return coords

                idx_u = make_coords(u_idx)
                idx_v = make_coords(v_idx)

                u_re = memref.LoadOp(in_r, idx_u).result
                u_im = memref.LoadOp(in_i, idx_u).result
                v_re = memref.LoadOp(in_r, idx_v).result
                v_im = memref.LoadOp(in_i, idx_v).result

                cos_c = arith.ConstantOp(f32, tw[j][0]).result
                sin_c = arith.ConstantOp(f32, tw[j][1]).result
                t_re, t_im = lower_complex_mul(v_re, v_im, cos_c, sin_c, arith)

                out_u_re = arith.AddFOp(u_re, t_re).result
                out_u_im = arith.AddFOp(u_im, t_im).result
                out_v_re = arith.SubFOp(u_re, t_re).result
                out_v_im = arith.SubFOp(u_im, t_im).result

                # store back to the natural positions u_idx and v_idx
                memref.StoreOp(out_u_re, out_r, idx_u)
                memref.StoreOp(out_u_im, out_i, idx_u)
                memref.StoreOp(out_v_re, out_r, idx_v)
                memref.StoreOp(out_v_im, out_i, idx_v)


def lower_stockham_fft(in_name, out_name, shape, axis, symtab, builder_ops_insert, f32, arith, memref, idx_type):
    # Expand into stages by inserting stockham_stage ops into the builder ops list.
    # The final stage is emitted directly into `out_name` so that the lowering
    # writes the final results into the user-declared output buffer (which may
    # be mapped to function outputs). Intermediate stages are emitted into
    # temporary names derived from out_name.
    # (axis handling is done below; support axis=None for ND)
    # If axis is None, perform Stockham sequentially across all axes (separable ND FFT)
    def bitrev(i, bits):
        r = 0
        for _ in range(bits):
            r = (r << 1) | (i & 1)
            i >>= 1
        return r

    cur_in = in_name
    # Build list of axes to process
    if axis is None:
        axes_to_process = list(range(len(shape)))
    else:
        if axis < 0:
            axis = len(shape) + axis
        axes_to_process = [axis]

    for ax in axes_to_process:
        L = shape[ax]
        stages_ax = int(math.log2(L))
        # bit-reverse permute into a temp for this axis
        br_name = f"{cur_in}_br_ax{ax}"
        bits = int(math.log2(L))
        pattern = [bitrev(i, bits) for i in range(L)]
        builder_ops_insert(("permute", cur_in, br_name, pattern, shape, ax, arith, memref, idx_type) if False else ("permute", cur_in, br_name, pattern, ax))
        # set working input for stages
        work_in = br_name
        # insert stages for this axis
        for s in range(stages_ax):
            if s == stages_ax - 1:
                next_name = f"{out_name}_ax{ax}" if ax != axes_to_process[-1] else out_name
            else:
                next_name = f"{out_name}_ax{ax}_stage{s}"
            builder_ops_insert(("stockham_stage", work_in, next_name, s, ax))
            work_in = next_name
        # after finishing this axis, set cur_in to the result for next axis
        cur_in = work_in

    # ensure final result is in out_name
    if cur_in != out_name:
        # final stage output is not the declared output; insert a copy
        # pattern here is identity across axis length of last processed axis
        last_ax = axes_to_process[-1]
        Lf = shape[last_ax]
        builder_ops_insert(("permute", cur_in, out_name, list(range(Lf)), last_ax))

# Append these two functions to ops/fft.py

def lower_cooley_tukey_stage(in_r, in_i, out_r, out_i, shape, axis, stage, f32, arith, memref, idx_type):
    """Single radix-2 stage (same as Stockham)."""
    return lower_stockham_stage(in_r, in_i, out_r, out_i, shape, axis, stage, f32, arith, memref, idx_type)

def lower_cooley_tukey_fft(in_name, out_name, shape, axis, symtab, builder_ops_insert, f32, arith, memref, idx_type):
    """Expand Cooley‑Tukey: bit‑reverse + log2(N) stages."""
    import math
    def bitrev(i, bits):
        r = 0
        for _ in range(bits):
            r = (r << 1) | (i & 1)
            i >>= 1
        return r

    cur_in = in_name
    if axis is None:
        axes_to_process = list(range(len(shape)))
    else:
        if axis < 0:
            axis = len(shape) + axis
        axes_to_process = [axis]

    for ax in axes_to_process:
        L = shape[ax]
        stages_ax = int(math.log2(L))
        # bit-reverse permutation
        br_name = f"{cur_in}_br_ax{ax}"
        bits = int(math.log2(L))
        pattern = [bitrev(i, bits) for i in range(L)]
        builder_ops_insert(("permute", cur_in, br_name, pattern, ax))
        work_in = br_name
        # radix-2 stages
        for s in range(stages_ax):
            if s == stages_ax - 1:
                next_name = f"{out_name}_ax{ax}" if ax != axes_to_process[-1] else out_name
            else:
                next_name = f"{out_name}_ax{ax}_stage{s}"
            builder_ops_insert(("cooley_tukey_stage", work_in, next_name, s, ax))
            work_in = next_name
        cur_in = work_in

    if cur_in != out_name:
        last_ax = axes_to_process[-1]
        Lf = shape[last_ax]
        builder_ops_insert(("permute", cur_in, out_name, list(range(Lf)), last_ax))
