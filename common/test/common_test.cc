#include "gtest/gtest.h"
// violates our requirements, thus has to go first
#include "common/Levenstein.h"
#include "common/common.h"

namespace sorbet::common {

TEST(CommonTest, Levenstein) { // NOLINT
    EXPECT_EQ(2, Levenstein::distance("Mama", "Papa", 10));
    EXPECT_EQ(5, Levenstein::distance("Ruby", "Scala", 10));
    EXPECT_EQ(3, Levenstein::distance("Java", "Scala", 10));
    EXPECT_EQ(INT_MAX, Levenstein::distance("Java", "S", 1));
}

} // namespace sorbet::common
