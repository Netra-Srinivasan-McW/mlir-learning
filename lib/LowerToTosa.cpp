#include "MyDialect/Passes.h"
#include "MyDialect/MyOps.h"
#include "MyDialect/MyDialect.h"

#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Tosa/IR/TosaOps.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Transforms/DialectConversion.h"

// including tablegen generated patterns
// placing this inside an anonymous namespace so that it doesn't overlap
// with same populate function in another pass
namespace { 
#include "LowerToTosa.inc" 
}

using namespace mlir;

namespace {

// 1. Conversion Pattern - const op (MyDialect -> Tosa)
struct ConstOpLowering : public OpConversionPattern<mydialect::ConstantOp> {
    // rementioned for inheriting constructors
    using OpConversionPattern<mydialect::ConstantOp>::OpConversionPattern;

    // LogicalResult - like bool for mlir returns mlir::success() or mlir::failure()
    // not necessary for matchandrewrite to be the only funciton name, can be some other name also
    LogicalResult matchAndRewrite(mydialect::ConstantOp op,  OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
        // 1. Validate result is a ranked tensor
        auto resultType = dyn_cast<RankedTensorType>(op.getType());
        if (!resultType)
            return rewriter.notifyMatchFailure(op, "result must be a ranked tensor");

        // 2. Validate attribute is DenseElementsAttr
        auto value = dyn_cast<DenseElementsAttr>(op.getInput());
        if (!value)
            return rewriter.notifyMatchFailure(op, "value must be DenseElementsAttr");
        
        // 3. Replace old op with tosa::ConstOp
        rewriter.replaceOpWithNewOp<tosa::ConstOp>(op, resultType, value);
        return success();
        
    }
};

// 2. Pass Definition - const op and add op (MyDialect -> Tosa)
struct LowerMyDialectToTosaPass : public PassWrapper<LowerMyDialectToTosaPass, OperationPass<ModuleOp>> {
    MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(LowerMyDialectToTosaPass)

    StringRef getArgument() const final { return "lower-mydialect-to-tosa"; }
    StringRef getDescription() const final {
    return "Lower mydialect ops to TOSA";
    }

    void getDependentDialects(DialectRegistry &registry) const override {
        registry.insert<tosa::TosaDialect>();
    }

    // runs the pass over the currently held operation
    void runOnOperation() override {
        ConversionTarget target(getContext());
        target.addLegalDialect<tosa::TosaDialect>();
        target.addLegalDialect<func::FuncDialect>();
        // target.addIllegalOp<mydialect::ConstantOp>();
        target.addIllegalDialect<mydialect::MyDialect>();

        RewritePatternSet patterns(&getContext());

        patterns.add<ConstOpLowering>(&getContext());
        // TableGen pattern for AddOp (generated from MyDialectToTosa.td):
        populateWithGenerated(patterns);

        if (failed(applyPartialConversion(getOperation(), target, std::move(patterns))))        
            signalPassFailure();
    }

};
} // namespace

namespace mlir {
namespace mydialect {

// defining the ones initialized in Passes.h
std::unique_ptr<Pass> createLowerMyDialectToTosaPass() {
    return std::make_unique<LowerMyDialectToTosaPass>();
}

void registerlowerMyDialectToTosaPass() {
    PassRegistration<LowerMyDialectToTosaPass>();
}

} // namespace mydialect
} // namespace mlir
