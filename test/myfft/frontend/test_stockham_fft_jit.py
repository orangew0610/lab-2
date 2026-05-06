# DFT(8) input[8] test using the algorithm decorator and MLIR generation, with JIT execution via bindings mode.

import numpy as np
from frontend.Python.fftc import algorithm 
from frontend.Python.ops.fft_mlir_runner import run_mlir_module
N = 8
# use stockham_fft path which emits a direct function writing into outputs
# create an Algorithm wrapper using the decorator
@algorithm(size=N)
def fft_test_stockham_fft(b):
    
    # new API: axis-aware; for 1D default axis (-1) is fine
    b.stockham_fft('input', 'output')
    #b.stockham_stage('input', 'output',0)
    #b.stockham_stage('output','output2',1)
# generate via bindings mode
mlir_text = fft_test_stockham_fft.compile_to_mlir(name='fft_test_stockham_fft', mode='bindings')

# Export function so ExecutionEngine can find it:
mlir_text2 = mlir_text.replace(') {\n', ') attributes { llvm.emit_c_interface } {\n', 1)
print(mlir_text2)
in_r = np.arange(N, dtype=np.float32)
in_i = np.zeros(N, dtype=np.float32)
out_r = np.zeros(N, dtype=np.float32)
out_i = np.zeros(N, dtype=np.float32)

results = run_mlir_module(mlir_text2, 'fft_test_stockham_fft', args=[in_r, in_i, out_r, out_i])
# results[2], results[3] are the output real/imag arrays (may be views)
print(results)
out_r_res = results[2] #or out_r
out_i_res = results[3] #or out_i

mlir_out = out_r_res.astype(np.complex64) + 1j * out_i_res.astype(np.complex64)


print('mlir_out =', mlir_out)

