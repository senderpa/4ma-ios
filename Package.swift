// swift-tools-version:5.9
//
// NOTE: This Package.swift exists for Swift Package Manager compatibility
// (e.g., if you want to import FourMA as a library in another project).
//
// To build and run the iOS app, open FourMA.xcodeproj in Xcode instead.

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
            path: "FourMA",
            exclude: ["Info.plist"]
        ),
    ]
)
