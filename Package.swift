// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FourMA",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "FourMA", targets: ["FourMA"]),
    ],
    targets: [
        .target(
            name: "FourMA",
            path: "FourMA"
        ),
    ]
)
