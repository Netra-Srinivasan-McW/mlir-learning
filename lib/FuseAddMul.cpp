#include "MyDialect/MyOps.h"
#include "MyDialect/MyDialect.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/PatternMatch.h"
#include "mlir/IR/TypeUtilities.h" // for getElementTypeOrSelf
#include "mlir/Pass/Pass.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"

// placing this inside an anonymous namespace so that it doesn't overlap
// with same populate funstion in another pass
namespace { 
#include "FuseAddMul.inc" 
}

using namespace mlir;

namespace mlir::mydialect {

void populateFuseAddMulPatterns(RewritePatternSet &patterns) {
  populateWithGenerated(patterns);
}

} // namespace mlir::mydialect

namespace {
struct FuseAddMulPass : public PassWrapper<FuseAddMulPass, OperationPass<ModuleOp>> {

  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(FuseAddMulPass)
  StringRef getArgument() const final { return "fuse-add-mul"; }
  StringRef getDescription() const final { return "Fuse add and mul operations"; }

  void runOnOperation() override {
    RewritePatternSet patterns(&getContext());
    mlir::mydialect::populateFuseAddMulPatterns(patterns);

    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
      signalPassFailure();
  }
};
} // namespace

namespace mlir::mydialect {

void registerFuseAddMulPass() {
  PassRegistration<FuseAddMulPass>();
}

} // namespace mlir::mydialect
