#ifndef FUSEADDMUL_TD
#define FUSEADDMUL_TD

//Note: In .td files, include is only used to include other TableGen files

// Add-Mul fusion pattern for `my_arith` dialect.

include "mlir/IR/PatternBase.td"
include "MyDialect/MyOps.td"


// 1. Check if contract is enabled for the op
// Op allows contraction if:
// a. It is an integer type (always safe to fuse), OR
// b. The contract attribute is explicitly set.

// Remember: if moving contents within "" to multiple lines replace "" with [{}]
def HasContract : Constraint<
    CPred < [{ ::llvm::isa<::mlir::IntegerType>(
        ::mlir::getElementTypeOrSelf (
            $0.getType()
        )
    ) || $0.getOwner()->hasAttr("contract") 
    }] >,
    "op is integer or allows contraction"
>;

// 2. Pattern-1 to check (a+b) * c -> fused_add_mul(a,b,c)
def UpliftAddLHSFuse : Pat<
    // Match : mulf(addf(a, b), c)
    (MulOp:$mulop
        (AddOp:$addop $a, $b),
        $c
    ),
    (FuseAddMulOp $a, $b, $c),
    [
        (HasContract $mulop),
        (HasContract $addop)
    ]
>;

// 3. Pattern-2 to check c * (a+b) -> fused_add_mul(a,b,c)
def UpliftAddRHSFuse : Pat<
    // Match : mul(c, add(a, b))
    (MulOp:$mulop $c,
        (AddOp:$addop $a, $b)
    ),
    (FuseAddMulOp $a, $b, $c),
    [
        (HasContract $mulop),
        (HasContract $addop)
    ]
>;






#endif // FUSEADDMUL_TD