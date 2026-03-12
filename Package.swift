// swift-tools-version: 5.10

// Package.swift
// Swift Package Manager manifest for the SwiftBlockbusters application.
// Defines the package name, supported platforms, dependencies, and build targets.

import PackageDescription

let package = Package(
    // The package name used by SPM to identify this project
    name: "SakilaApp",

    // Restrict to macOS 14+ (Sonoma) for modern SwiftUI features like @Observable
    platforms: [
        .macOS(.v14)
    ],

    // External dependencies fetched by SPM
    dependencies: [
        // mysql-nio: Vapor's async MySQL driver built on SwiftNIO for non-blocking database access
        .package(url: "https://github.com/vapor/mysql-nio.git", from: "1.0.0")
    ],

    // Build targets that make up this package
    targets: [
        // Main executable target containing the SwiftUI application
        .executableTarget(
            name: "SakilaApp",
            dependencies: [
                // Link against the MySQLNIO product from the mysql-nio package
                .product(name: "MySQLNIO", package: "mysql-nio")
            ],
            path: "Sources/SakilaApp",
            // Exclude Info.plist from compilation — it is used as a resource by the build system
            exclude: ["Info.plist"]
        )
    ]
)
