cmake_minimum_required(VERSION 3.20)

project (MyMLIRProject LANGUAGES CXX)

find_package(MLIR REQUIRED CONFIG)

list(APPEND CMAKE_MODULE_PATH "${MLIR_CMAKE_DIR}")

include(AddLLVM)
include(AddMLIR)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

include_directories(
    ${LLVM_INCLUDE_DIRS}
    ${MLIR_INCLUDE_DIRS}
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_BINARY_DIR}
)

# dialect declarations and definitions
set(LLVM_TARGET_DEFINITIONS
    ${PROJECT_SOURCE_DIR}/include/MyDialect/MyDialect.td
)

mlir_tablegen(MyDialect.h.inc -gen-dialect-decls)
mlir_tablegen(MyDialect.cpp.inc -gen-dialect-defs)

add_public_tablegen_target(MyDialectDialectIncGen)

# operation declarations and definitions
set(LLVM_TARGET_DEFINITIONS
    ${PROJECT_SOURCE_DIR}/include/MyDialect/MyOps.td
)

mlir_tablegen(MyOps.h.inc -gen-op-decls)
mlir_tablegen(MyOps.cpp.inc -gen-op-defs)

add_public_tablegen_target(MyDialectOpsIncGen)

set(LLVM_TARGET_DEFINITIONS ${PROJECT_SOURCE_DIR}/include/MyDialect/MyDialectToTosa.td)
mlir_tablegen(LowerToTosa.inc -gen-rewriters)
add_public_tablegen_target(MyDialectLowerToTosaIncGen)

# build custom dialect library
add_library(MyDialect
    lib/MyDialect.cpp
    lib/MyOps.cpp
    lib/LowerToTosa.cpp
)

add_dependencies(MyDialect
    MyDialectDialectIncGen
    MyDialectOpsIncGen
    MyDialectLowerToTosaIncGen
)

target_link_libraries(MyDialect PUBLIC 
    MLIRIR 
    MLIRPass 
    MLIRTransforms 
    MLIRTosaDialect
)

# build custom optimizer tool
add_executable(my-opt tools/my-opt.cpp)

target_compile_options(MyDialect PRIVATE -fno-rtti)
target_compile_options(my-opt PRIVATE -fno-rtti)

target_link_libraries(my-opt PRIVATE
    MyDialect
    MLIROptLib
    MLIRFuncDialect
    MLIRTosaDialect
)