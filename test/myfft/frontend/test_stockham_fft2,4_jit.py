import numpy as np
from frontend.Python.fftc import algorithm
from frontend.Python.ops.fft_mlir_runner import run_mlir_module
shape = (2,2,2,2) #Test a 2D FFT with shape (2,4) to verify multi-axis Stockham handling. This is a small size for easy verification; can be increased as needed.
# prepare input
total = 1
for d in shape:
    total *= d
@algorithm(size=shape)
def myfft(b):
    b.input('in')
    b.output('out')
    #b.dft('in','out')
    # default (axis=None) -> perform full ND Stockham across all axes
    b.stockham_fft('in','out')


mlir_text = myfft.compile_to_mlir(N=shape, name='fft_staged_test', mode='bindings')
mlir_text2 = mlir_text.replace('func.func private @fft_staged_test(', 'func.func @fft_staged_test(')
mlir_text2 = mlir_text2.replace(') {\n', ') attributes { llvm.emit_c_interface } {\n', 1)


in_r = np.arange(total, dtype=np.float32).reshape(shape)
in_i = np.zeros(shape, dtype=np.float32).reshape(shape)
out_r = np.zeros(shape, dtype=np.float32)
out_i = np.zeros(shape, dtype=np.float32)
print(in_r)
print('Running ExecutionEngine...')
results = run_mlir_module(mlir_text2, 'fft_staged_test', [in_r, in_i, out_r, out_i])
print('run done')
if results[2] is not None and results[3] is not None:
    out_r_res = results[2]
    out_i_res = results[3]
else:
    out_r_res = out_r
    out_i_res = out_i

mlir_out = out_r_res.astype(np.complex64) + 1j*out_i_res.astype(np.complex64)
np_ref = np.fft.fftn((in_r.astype(np.complex64) + 1j*in_i.astype(np.complex64)))#.ravel()
#print('L2 diff =', np.linalg.norm(mlir_out.ravel() - np_ref))
print('mlir_out =', np.round(mlir_out,2))#.ravel()
print('np_ref   =', np.round(np_ref,2))
'''
import numpy as np

def stockham_fft(x):
    """
    Stockham 自排序 FFT，输入 x 为一维复数数组，长度 N 为 2 的幂。
    返回 FFT 结果（与 np.fft.fft 相同）。
    """
    N = len(x)
    x = np.array(x, dtype=np.complex128)
    y = np.zeros_like(x)
    step = 1
    while step < N:
        # 预计算当前 step 的旋转因子
        twiddle = np.exp(-2j * np.pi * np.arange(step) / (2 * step))
        for i in range(0, N, 2 * step):
            # 上下两部分
            u = x[i : i + step]
            v = x[i + step : i + 2 * step]
            # 复数乘法 v * twiddle
            t = v * twiddle
            # 蝶形
            out1 = u + t
            out2 = u - t
            # 交错存储
            y[i : i + 2 * step : 2] = out1
            y[i + 1 : i + 2 * step : 2] = out2
        x, y = y, x
        step <<= 1
    return x

# 测试
if __name__ == '__main__':
    for N in [4, 8]:
        x = np.arange(N, dtype=np.complex128)
        my_fft = stockham_fft(x)
        np_fft = np.fft.fft(x)
        print(f"N={N}, L2 diff = {np.linalg.norm(my_fft - np_fft):.2e}")
        print("My FFT:", my_fft)
        print("NumPy:", np_fft)
'''