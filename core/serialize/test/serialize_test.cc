#include "gtest/gtest.h"
// has to go first as it violates are requirements
#include "core/serialize/pickler.h"
#include "core/serialize/serialize.h"
#include "spdlog/sinks/stdout_color_sinks.h"
#include "spdlog/spdlog.h"

using namespace std;

namespace spd = spdlog;
namespace sorbet::core::serialize {

auto logger = spd::stderr_color_mt("serialize_test");

TEST(SerializeTest, U4) { // NOLINT
    Pickler p;
    p.putU4(0);
    p.putU4(1);
    p.putU4(4294967295);
    UnPickler u(p.result(Serializer::GLOBAL_STATE_COMPRESSION_DEGREE).data(), *logger);
    EXPECT_EQ(u.getU4(), 0);
    EXPECT_EQ(u.getU4(), 1);
    EXPECT_EQ(u.getU4(), 4294967295);
}

TEST(SerializeTest, U4U1) { // NOLINT
    Pickler p;
    p.putU4(0);
    p.putU4(0);
    p.putStr("aaaaa");
    p.putU4(0);
    p.putU4(0);
    p.putU1(1);
    p.putU4(1);
    p.putU1(0);
    p.putU4(4294967295);
    UnPickler u(p.result(Serializer::GLOBAL_STATE_COMPRESSION_DEGREE).data(), *logger);
    EXPECT_EQ(u.getU4(), 0);
    EXPECT_EQ(u.getU4(), 0);
    EXPECT_EQ(u.getStr(), "aaaaa");
    EXPECT_EQ(u.getU4(), 0);
    EXPECT_EQ(u.getU4(), 0);
    EXPECT_EQ(u.getU1(), 1);
    EXPECT_EQ(u.getU4(), 1);
    EXPECT_EQ(u.getU1(), 0);
    EXPECT_EQ(u.getU4(), 4294967295);
}

TEST(SerializeTest, U8) { // NOLINT
    Pickler p;
    p.putS8(0);
    p.putS8(1);
    p.putS8(-1);
    p.putS8(9223372036854775807);
    UnPickler u(p.result(Serializer::GLOBAL_STATE_COMPRESSION_DEGREE).data(), *logger);
    EXPECT_EQ(u.getS8(), 0);
    EXPECT_EQ(u.getS8(), 1);
    EXPECT_EQ(u.getS8(), -1);
    EXPECT_EQ(u.getS8(), 9223372036854775807);
}

TEST(SerializeTest, Strings) { // NOLINT
    Pickler p;
    p.putStr("");
    p.putStr("a");
    p.putStr("aaaaa");
    p.putStr("1");
    p.putStr("Z");
    p.putStr("НЯ");
    p.putStr("\0\0\0\t\n\f\rНЯЯЯЯЯ");
    UnPickler u(p.result(Serializer::GLOBAL_STATE_COMPRESSION_DEGREE).data(), *logger);
    EXPECT_EQ(u.getStr(), "");
    EXPECT_EQ(u.getStr(), "a");
    EXPECT_EQ(u.getStr(), "aaaaa");
    EXPECT_EQ(u.getStr(), "1");
    EXPECT_EQ(u.getStr(), "Z");
    EXPECT_EQ(u.getStr(), "НЯ");
    EXPECT_EQ(u.getStr(), "\0\0\0\t\n\f\rНЯЯЯЯЯ");
}

} // namespace sorbet::core::serialize
