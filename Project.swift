import ProjectDescription

let project = Project(
    name: "LLMKit",
    organizationName: "m",
    settings: .settings(
        defaultSettings: .recommended
    ),
    targets: [
        .target(
            name: "LLMKit",
            destinations: .iOS,
            product: .framework,
            bundleId: "m.walnut.llmkit",
            sources: [
                "Sources/**"
            ],
            dependencies: [
                // No external dependencies needed for now
                // Can add SwiftUI implicitly through iOS platform
            ],
            settings: .settings(
                base: [
                    "SWIFT_VERSION": "5.0",
                    "IPHONEOS_DEPLOYMENT_TARGET": "15.0"
                ],
                configurations: [
                    .debug(name: "Debug"),
                    .release(name: "Release")
                ],
                defaultSettings: .recommended
            )
        ),
        .target(
            name: "LLMKitTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "m.walnut.llmkit.tests",
            sources: [
                "Tests/**"
            ],
            dependencies: [
                .target(name: "LLMKit")
            ]
        )
    ]
)
