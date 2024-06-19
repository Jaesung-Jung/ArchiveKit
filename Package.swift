// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ArchiveKit",
  platforms: [
    .iOS(.v13),
    .macCatalyst(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "ArchiveKit",
      targets: ["ArchiveKit"]
    ),
  ],
  targets: [
    .target(
      name: "ArchiveKit",
      dependencies: ["minizip407"]
    ),
    .target(
      name: "minizip120",
      publicHeadersPath: ".",
      cSettings: [
        .define("HAVE_AES"),
        .define("HAVE_APPLE_COMPRESSION"),
        .unsafeFlags(["-w"])
      ]
    ),
    .target(
      name: "minizip407",
      exclude: ["LICENSE", "README.md"],
      publicHeadersPath: ".",
      cSettings: [
        .define("HAVE_WZAES"),
        .define("HAVE_ZLIB"),
        .define("HAVE_ICONV"),
        .define("HAVE_LIBBSD"),
        .define("HAVE_ARC4RANDOM"),
        .define("HAVE_LIBCOMP"),
        .define("HAVE_BZIP2"),
        .define("HAVE_PKCRYPT"),
        .define("HAVE_STDINT_H"),
        .define("ZLIB_COMPAT"),
      ],
      linkerSettings: [
        .linkedLibrary("z"),
        .linkedLibrary("bz2"),
        .linkedLibrary("iconv")
      ]
    ),
    .testTarget(
      name: "ArchiveKitTests",
      dependencies: ["ArchiveKit"],
      resources: [
        .process("Resources")
      ]
    ),
  ]
)
