#ifndef MYDIALECT_PASSES_H
#define MYDIALECT_PASSES_H

#include <memory>

namespace mlir {
class Pass;

namespace mydialect {
// unique ptr for automatic memory allocation and memory deletion
// pass creation initialization
std::unique_ptr<Pass> createLowerMyDialectToTosaPass();
std::unique_ptr<Pass> createFuseAddMulPass();

// Registers the pass flag '--lower-mydialect-to-tosa' in tools
void registerlowerMyDialectToTosaPass();

// Registers the pass flag '--fuse-add-mul' in tools
void registerFuseAddMulPass();

} // namespace mydialect
} // namespace mlir

#endif // MYDIALECT_PASSES_H