#include "MyDialect/MyDialect.h"
#include "MyDialect/Passes.h"

#include "mlir/IR/DialectRegistry.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Tosa/IR/TosaOps.h"

int main(int argc, char **argv) {
    mlir::DialectRegistry registry;

    // Register our custom dialect.
    registry.insert<mlir::mydialect::MyDialect>();
    registry.insert<mlir::func::FuncDialect>();
    registry.insert<mlir::tosa::TosaDialect>();

    // Register pass CLI flag
    mlir::mydialect::registerlowerMyDialectToTosaPass();

    return mlir::failed(
        mlir::MlirOptMain(
            argc,
            argv,
            "My Dialect Optimizer\n",
            registry
        )
    );
}