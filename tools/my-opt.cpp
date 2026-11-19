#include "MyDialect/MyDialect.h"

#include "mlir/IR/DialectRegistry.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"

int main(int argc, char **argv) {
    mlir::DialectRegistry registry;

    // Register our custom dialect.
    registry.insert<mlir::mydialect::MyDialect>();
    registry.insert<mlir::func::FuncDialect>();

    return mlir::failed(
        mlir::MlirOptMain(
            argc,
            argv,
            "My Dialect Optimizer\n",
            registry
        )
    );
}