import numpy as np
from frontend.Python.fftc import algorithm 
from frontend.Python.ops.fft_mlir_runner import run_mlir_module


@algorithm(size=4)
def test_ops(b):
    b.input('input')
    
    b.twiddle_mul('input', 't1', 2, 2)
    b.butterfly('input', 't1', 't1', 'o1', 'o2')
    b.permute('o1', 'p1', [0,2,1,3])
    b.reshape('p1', 'r1', (4,))
    #b.stockham_stage('r1', 's1', 0)
    b.stockham_fft('s1', 'output')

try:
    mlir_out = test_ops.compile_to_mlir(mode='bindings')
    print('--- BINDINGS MLIR (truncated) ---')
    print(mlir_out[:1000])
except Exception as e:
    import traceback
    print('ERROR during compile_to_mlir: ', type(e).__name__, e)
    traceback.print_exc()
