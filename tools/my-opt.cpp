#include "MyDialect/MyDialect.h"
#include "MyDialect/Passes.h"

#include "mlir/IR/DialectRegistry.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Tosa/IR/TosaOps.h"

#include "mlir/Transforms/Passes.h" // for --canonicalize registration

int main(int argc, char **argv) {
    mlir::DialectRegistry registry;

    // Register our custom dialect.
    registry.insert<mlir::mydialect::MyDialect>();
    registry.insert<mlir::func::FuncDialect>();
    registry.insert<mlir::tosa::TosaDialect>();

    // Register pass CLI flag
    mlir::mydialect::registerlowerMyDialectToTosaPass();
    mlir::mydialect::registerFuseAddMulPass();

    // Register MLIR's standard transform passes (enables --canonicalize, --cse, etc.)
    mlir::registerCanonicalizerPass();

    return mlir::failed(
        mlir::MlirOptMain(
            argc,
            argv,
            "My Dialect Optimizer\n",
            registry
        )
    );
}