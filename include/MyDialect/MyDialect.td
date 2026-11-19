#ifndef MYDIALECT_DIALECT_TD
#define MYDIALECT_DIALECT_TD

include "mlir/IR/OpBase.td"

def MyDialect : Dialect {
    let name = "mydialect";
    let cppNamespace = "::mlir::mydialect";
}

// if the below endif is not mentioned with //dialect_name, then endif undefined error arises
#endif // MYDIALECT_DIALECT_TD