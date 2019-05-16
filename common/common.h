#ifndef SORBET_COMMON_HPP
#define SORBET_COMMON_HPP

#if __cplusplus < 201402L
#define STRINGIZE(x) "C++ = " #x
#define SSTRINGIZE(x) STRINGIZE(x)
#pragma message(SSTRINGIZE(__cplusplus))
static_assert(false, "Need c++14 to compile this codebase");
#endif

#include "absl/algorithm/container.h"
#include "absl/container/flat_hash_map.h"
#include "absl/container/flat_hash_set.h"
#include "absl/container/inlined_vector.h"
#include "pdqsort.h"
#include "spdlog/fmt/fmt.h"
#include "spdlog/spdlog.h"
#include <cstring>
#include <functional>
#include <stdint.h>
#include <string>
#include <string_view>
#include <type_traits>
#include <typeinfo>
#include <vector>

#if !defined(NDEBUG)
// So you can use `cout` when debugging. Not included in production as it is a
// performance hit.
#include <iostream>
#endif

namespace sorbet {

template <class T, size_t N> using InlinedVector = absl::InlinedVector<T, N>;
template <class K, class V> using UnorderedMap = absl::flat_hash_map<K, V>;
template <class E> using UnorderedSet = absl::flat_hash_set<E>;
// Uncomment to make vectors debuggable
// template <class T, size_t N> using InlinedVector = std::vector<T>;

#if defined(NDEBUG) && !defined(FORCE_DEBUG)
constexpr bool debug_mode = false;
#undef DEBUG_MODE
#else
#define DEBUG_MODE
constexpr bool debug_mode = true;
#endif

#if !defined(EMSCRIPTEN)
constexpr bool emscripten_build = false;
#else
constexpr bool emscripten_build = true;
#endif

#if !defined(FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION)
constexpr bool fuzz_mode = false;
#else
constexpr bool fuzz_mode = true;
#endif

#define _MAYBE_ADD_COMMA(...) , ##__VA_ARGS__
#define ENFORCE(x, ...)                                                                             \
    ((::sorbet::debug_mode && !(x)) ? ({                                                            \
        ::sorbet::Exception::failInFuzzer();                                                        \
        if (stopInDebugger()) {                                                                     \
            (void)!(x);                                                                             \
        }                                                                                           \
        ::sorbet::Exception::enforce_handler(#x, __FILE__, __LINE__ _MAYBE_ADD_COMMA(__VA_ARGS__)); \
    })                                                                                              \
                                    : false)

#define DEBUG_ONLY(X) \
    if (debug_mode) { \
        X;            \
    }

constexpr bool skip_check_memory_layout = debug_mode || emscripten_build;

template <typename ToCheck, std::size_t ExpectedSize, std::size_t RealSize = sizeof(ToCheck)> struct check_size {
    static_assert(skip_check_memory_layout || ExpectedSize == RealSize, "Size is off!");
};

template <typename ToCheck, std::size_t ExpectedAlign, std::size_t RealAlign = alignof(ToCheck)> struct check_align {
    static_assert(skip_check_memory_layout || ExpectedAlign == RealAlign, "Align is off!");
};

#ifdef UNUSED
#elif defined(__GNUC__)
#define UNUSED(x) UNUSED_##x __attribute__((unused))
#elif defined(__LCLINT__)
#define UNUSED(x) /*@unused@*/ x
#else
#define UNUSED(x) x
#endif

#define CheckSize(T, ExpSize, ExpAlign)                                              \
    inline void _##T##is##ExpSize##_bytes_long_() {                                  \
        sorbet::check_size<T, ExpSize> UNUSED(_##T##is##ExpSize##_bytes_long);       \
        sorbet::check_align<T, ExpAlign> UNUSED(_##T##is##ExpAlign##_bytes_aligned); \
    }

/**
 * Shorter aliases for unsigned ints of specified byte widths.
 */
typedef uint8_t u1;
CheckSize(u1, 1, 1);

typedef uint16_t u2;
CheckSize(u2, 2, 2);

typedef uint32_t u4;
CheckSize(u4, 4, 4);

typedef uint64_t u8;
CheckSize(u8, 8, 8);

template <class From, class To> To *fast_cast(From *what) {
    constexpr bool isFinal = std::is_final<To>::value;
    if (std::is_same<From, To>::value)
        return static_cast<To *>(what);
    if (what == nullptr) {
        return nullptr;
    }
    if (isFinal) {
        From &nonNull = *what;
        const std::type_info &ty = typeid(nonNull);
        if (ty == typeid(To))
            return static_cast<To *>(what);
        return nullptr;
    }
    return dynamic_cast<To *>(what);
};

class FileOps final {
public:
    static bool exists(std::string_view filename);
    static std::string read(std::string_view filename);
    static void write(std::string_view filename, const std::vector<sorbet::u1> &data);
    static void append(std::string_view filename, std::string_view text);
    static void write(std::string_view filename, std::string_view text);
    /**
     * Returns a list of all files in the given directory. Returns paths that include the path to directory.
     * Throws FileNotFoundException if path does not exist, and FileNotDirException if path is not a directory.
     */
    static std::vector<std::string> listFilesInDir(std::string_view path, UnorderedSet<std::string> extensions,
                                                   bool recursive,
                                                   const std::vector<std::string> &absoluteIgnorePatterns,
                                                   const std::vector<std::string> &relativeIgnorePatterns);
    /**
     * Returns 'true' if the file at the given path is ignored.
     * See sorbet::options for information on absolute and relative ignore patterns.
     */
    static bool isFileIgnored(std::string_view basePath, std::string_view filePath,
                              const std::vector<std::string> &absoluteIgnorePatterns,
                              const std::vector<std::string> &relativeIgnorePatterns);
    static std::string_view getFileName(std::string_view path);
    static std::string_view getExtension(std::string_view path);
    /**
     * Reads data from the given file descriptor, and stores it into the output buffer.
     * Reads up to `output.size()` bytes. Timeout is specified in milliseconds.
     * Returns:
     * - Length of data read if > 0.
     * - 0 if timeout occurs.
     *
     * Throws FileReadException on EOF or error.
     */
    static int readFd(int fd, std::vector<char> &output, int timeoutMs = 100);
    /**
     * Attempts to read data up to a newline (\n) from the given file descriptor.
     * Timeout is specified in milliseconds.
     *
     * Stores any extra bits read into `buffer`.
     *
     * Returns:
     * - nullopt if timeout occurs or read() did not yield a newline.
     * - string if a line was found. The string does not contain the ending newline character.
     *
     * Throws FileReadException on EOF or error.
     */
    static std::optional<std::string> readLineFromFd(int fd, std::string &buffer, int timeoutMs = 100);
};

} // namespace sorbet

std::string demangle(const char *mangled);

namespace fmt {
template <typename It, typename Char, class UnaryOp, typename UnaryOpResult> struct arg_map_join {
    It begin;
    It end;
    basic_string_view<Char> sep;
    const UnaryOp &mapper;

    arg_map_join(It begin, It end, basic_string_view<Char> sep, const UnaryOp &mapper)
        : begin(begin), end(end), sep(sep), mapper(mapper) {}
};

template <typename It, typename Char, class UnaryOp, typename UnaryOpResult>
struct formatter<arg_map_join<It, Char, UnaryOp, UnaryOpResult>, Char> : formatter<UnaryOpResult, Char> {
    template <typename FormatContext>
    auto format(const arg_map_join<It, Char, UnaryOp, UnaryOpResult> &value, FormatContext &ctx)
        -> decltype(ctx.out()) {
        typedef formatter<UnaryOpResult, Char> base;

        auto it = value.begin;
        auto out = ctx.out();
        if (it != value.end) {
            out = base::format(std::invoke(value.mapper, *it++), ctx);
            while (it != value.end) {
                out = std::copy(value.sep.begin(), value.sep.end(), out);
                ctx.advance_to(out);
                out = base::format(std::invoke(value.mapper, *it++), ctx);
            }
        }
        return out;
    }
};

template <typename It, class UnaryOp> auto map_join(It begin, It end, std::string_view sep, const UnaryOp &mapper) {
    return arg_map_join<It, char, UnaryOp,
                        typename std::result_of<UnaryOp(typename std::iterator_traits<It>::value_type)>::type>(
        begin, end, sep, mapper);
}
template <typename Container, class UnaryOp>
auto map_join(const Container &collection, std::string_view sep, const UnaryOp &mapper) {
    return arg_map_join<typename Container::const_iterator, char, UnaryOp,
                        typename std::result_of<UnaryOp(
                            typename std::iterator_traits<typename Container::const_iterator>::value_type)>::type>(
        collection.begin(), collection.end(), sep, mapper);
}
} // namespace fmt

template <class Container, class Compare> inline void fast_sort(Container &container, Compare &&comp) {
    pdqsort(container.begin(), container.end(), std::forward<Compare>(comp));
};

template <class Container> inline void fast_sort(Container &container) {
    pdqsort(container.begin(), container.end());
};

/* use fast_sort */
#pragma GCC poison sort c_sort

/* use absl::c_ alternatives */
#pragma GCC poison any_of find_if linear_search min_element max_element iota all_of
// I wish I could add replace and find, but those names are too generic
//         accumulate upper_bound are used by <random>
//         lower_bound is needed for parser

/* String handling functions. Use C++ alternatives */
#pragma GCC poison strcpy wcscpy stpcpy wcpcpy
#pragma GCC poison strdup
#pragma GCC poison gets puts
#pragma GCC poison strcat wcscat
#pragma GCC poison wcrtomb wctob
#pragma GCC poison sprintf vsprintf vfprintf
#pragma GCC poison asprintf vasprintf
#pragma GCC poison strncpy wcsncpy
#pragma GCC poison strtok wcstok

/* Signal related */
#pragma GCC poison longjmp siglongjmp
#pragma GCC poison setjmp sigsetjmp

/* File API's */
#pragma GCC poison tmpnam tempnam

/* Misc */
#pragma GCC poison cuserid
#pragma GCC poison rexec rexec_af

#include "Exception.h"
#include "JSON.h"
#include "Levenstein.h"
#endif
