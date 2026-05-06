import numpy as np
from frontend.Python.fftc import algorithm
from frontend.Python.ops.fft_mlir_runner import run_mlir_module

N = 8

@algorithm(size=N)
def fft_test_cooley_tukey(b):
    b.cooley_tukey_fft('input', 'output', N)

mlir_text = fft_test_cooley_tukey.compile_to_mlir(name='cooley_tukey_fft_test', mode='bindings')
mlir_text2 = mlir_text.replace(') {\n', ') attributes { llvm.emit_c_interface } {\n', 1)
print(mlir_text2)

in_r = np.arange(N, dtype=np.float32)
in_i = np.zeros(N, dtype=np.float32)
out_r = np.zeros(N, dtype=np.float32)
out_i = np.zeros(N, dtype=np.float32)

results = run_mlir_module(mlir_text2, 'cooley_tukey_fft_test', args=[in_r, in_i, out_r, out_i])

out_r_res = results[2]
out_i_res = results[3]
mlir_out = out_r_res.astype(np.complex64) + 1j * out_i_res.astype(np.complex64)

print("Cooley-Tukey FFT result:", mlir_out)
expected = np.fft.fft(in_r + 1j*in_i)
print("Numpy FFT result   :", expected)
print("Max error:", np.max(np.abs(mlir_out - expected)))
