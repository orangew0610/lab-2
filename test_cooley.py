import numpy as np
from frontend.Python.fftc import algorithm

@algorithm(size=8)
def my_fft(b):
    b.cooley_tukey_fft('input', 'output', 8)

mlir_text = my_fft.compile_to_mlir(mode='bindings')
print(mlir_text)