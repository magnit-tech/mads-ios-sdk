import ProjectDescription

let nameAttribute: Template.Attribute = .required("name")

let template = Template(
    description: "UIKit app template",
    attributes: [
        nameAttribute
    ],
    items: [
        .file(
            path: "\(nameAttribute)/Sources/AppDelegate.swift",
            templatePath: "AppDelegate.stencil"
        ),
        .file(
            path: "\(nameAttribute)/Sources/ViewController.swift",
            templatePath: "ViewController.stencil"
        ),
        .file(
            path: "\(nameAttribute)/Tests/\(nameAttribute)Tests.swift",
            templatePath: "Tests.stencil"
        ),
        .file(
            path: "Project.swift",
            templatePath: "Project.stencil"
        )
    ]
)
