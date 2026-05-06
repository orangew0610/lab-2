This folder contains simple smoke tests for the FFT frontend lowering.

- test_stockham_buffer_mapping_correct.py
  - Uses builder symbol 'input' which should map to function arguments (%arg0/%arg1).
  - Asserts that lowering loads from %arg0/%arg1 (no alloc for input).

- test_stockham_buffer_mapping_bad.py
  - Uses an unregistered buffer name 's1'. The lowering currently allocates a temp buffer
    (memref.alloc) because 's1' is not mapped to function inputs.
  - Asserts that memref.alloc appears in the generated MLIR.

Run tests with:

python3 test/myfft/frontend/test_stockham_buffer_mapping_correct.py
python3 test/myfft/frontend/test_stockham_buffer_mapping_bad.py


Notes:
- These are simple smoke tests to illustrate buffer mapping behavior. For a
  production test-suite integrate with the project's test runner (lit/pytest).
