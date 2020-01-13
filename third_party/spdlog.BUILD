cc_library(
    name = "spdlog",
    srcs = [],
    hdrs = glob([
        "include/spdlog/**/*.h",
        "include/spdlog/**/*.cc",
    ]),
    copts = [
        "-Iexternal/spdlog/",
    ],
    includes = [
        "include/",
    ],
    linkopts = [
        "-lpthread",
    ],
    linkstatic = select({
        "@com_stripe_ruby_typer//tools/config:linkshared": 0,
        "//conditions:default": 1,
    }),
    visibility = ["//visibility:public"],
)
