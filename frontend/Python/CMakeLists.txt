# CMakeLists.txt — FTM Python frontend package.
#
# Copies all .py files into build/python_packages/ftm/compiler/ so that:
#   PYTHONPATH=build/python_packages/ftm python3 -c "from compiler import FTMCompiler"
# or more commonly:
#   PYTHONPATH=build/python_packages python3 -c "from ftm.compiler import FTMCompiler"

find_package(Python3 ${LLVM_MINIMUM_PYTHON_VERSION} REQUIRED
             COMPONENTS Interpreter Development.Module)

set(FTM_PYTHON_PACKAGES_DIR ${CMAKE_BINARY_DIR}/python_packages)

# Create the ftm.compiler package directories
file(MAKE_DIRECTORY ${FTM_PYTHON_PACKAGES_DIR}/ftm)
file(MAKE_DIRECTORY ${FTM_PYTHON_PACKAGES_DIR}/ftm/compiler)
# Top-level ftm/__init__.py
file(WRITE ${FTM_PYTHON_PACKAGES_DIR}/ftm/__init__.py "")
# ftm/compiler/__init__.py is copied from source below

# Recursively retrieve all python files from the current directory.
file(GLOB_RECURSE ALL_PY_FILES RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*.py")

set(PYTHON_OUTPUT_FILES "")
foreach(FILE ${ALL_PY_FILES})
    get_filename_component(REL_DIR "${FILE}" DIRECTORY)
    set(SRC "${CMAKE_CURRENT_SOURCE_DIR}/${FILE}")
    set(DEST_DIR "${FTM_PYTHON_PACKAGES_DIR}/ftm/compiler/${REL_DIR}")
    set(DEST_FILE "${FTM_PYTHON_PACKAGES_DIR}/ftm/compiler/${FILE}")

    add_custom_command(
        OUTPUT "${DEST_FILE}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${DEST_DIR}"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${SRC}" "${DEST_FILE}"
        DEPENDS "${SRC}"
        COMMENT "Syncing ${FILE}"
        VERBATIM
    )

    list(APPEND PYTHON_OUTPUT_FILES "${DEST_FILE}")
endforeach()

add_custom_target(python-package-ftm
    ALL DEPENDS ${PYTHON_OUTPUT_FILES}
    COMMENT "Syncing FTM python package files"
)
