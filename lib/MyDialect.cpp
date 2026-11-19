#include "MyDialect/MyDialect.h"
#include "MyDialect/MyOps.h"

#include "MyDialect.cpp.inc"

using namespace mlir;
using namespace mlir::mydialect;

void MyDialect::initialize() {
    addOperations<
        #define GET_OP_LIST
        #include "MyOps.cpp.inc"
    >();
    // addOperations<AddOp>();
    // addOperations<ConstantOp>();
}