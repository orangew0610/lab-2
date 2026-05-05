configure_lit_site_cfg(
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.site.cfg.py.in
  ${CMAKE_CURRENT_BINARY_DIR}/lit.site.cfg.py
  MAIN_CONFIG
  ${CMAKE_CURRENT_SOURCE_DIR}/lit.cfg.py
)

set(MATRIX_CODEGEN_TEST_DEPENDS
  llc
  clang
  FileCheck
  count
  not
)

add_lit_testsuite(check-matrix-codegen "Running Matrix CodeGen tests"
  ${CMAKE_CURRENT_BINARY_DIR}
  DEPENDS ${MATRIX_CODEGEN_TEST_DEPENDS}
)
set_target_properties(check-matrix-codegen PROPERTIES FOLDER "Tests")
