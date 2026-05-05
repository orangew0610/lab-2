from frontend.Python.fftc import algorithm 

# create an Algorithm wrapper using the decorator
# python3 test/myfft/frontend/test_dft.py
@algorithm(size=2)
def myfft(b):
    b.dft('x')

# generate via bindings mode
mlir_bind = myfft.compile_to_mlir(mode='bindings')
print('--- BINDINGS MODE  ---')
print(mlir_bind)
