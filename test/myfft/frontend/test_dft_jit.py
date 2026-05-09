import numpy as np
from frontend.Python.fftc import algorithm 
from frontend.Python.ops.fft_mlir_runner import run_mlir_module
#correctness test for DFT 
N = (2,2,2)
total = np.prod(N)
np_res=np.fft.fftn(np.arange(total).reshape(N))
print('np_res =', np_res)
# use dft path which emits a direct function writing into outputs
# create an Algorithm wrapper using the decorator
@algorithm(size = N)
def fft_test_dft(b):
    b.dft('input')

# generate via bindings mode
mlir_text = fft_test_dft.compile_to_mlir(name='fft_test_dft',mode='bindings')

# Export function so ExecutionEngine can find it:
mlir_text2 = mlir_text.replace(') {\n', ') attributes { llvm.emit_c_interface } {\n', 1)
#print(mlir_text2)
in_r = np.arange(total, dtype=np.float32).reshape(N)
in_i = np.zeros(N, dtype=np.float32)
out_r = np.zeros(N, dtype=np.float32)
out_i = np.zeros(N, dtype=np.float32)

results = run_mlir_module(mlir_text2, 'fft_test_dft', args=[in_r, in_i, out_r, out_i])
# results[2], results[3] are the output real/imag arrays (may be views)
out_r_res = results[2] #or out_r
out_i_res = results[3] #or out_i
#print(out_r_res)
#print(out_i_res)

mlir_out = out_r_res.astype(np.complex64) + 1j * out_i_res.astype(np.complex64)


print('mlir_out =', np.round(mlir_out,2))

