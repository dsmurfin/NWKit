# NWKit

A Swift Package (SPM) wrapper on Network.framework.

Note: This project is a work in progress and will change a lot.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

Requires Swift 5.7  
macOS 10.15+, iOS 13+

### Installing

#### Xcode 14+

To add the package dependency to your Xcode project, select File > Swift Packages > Add Package Dependency and enter the repository URL:

https://github.com/dsmurfin/NWKit

#### Swift Package Manager

Simply add the package dependency to your Package.swift and depend on "NWKit" in the necessary targets:

``` dependencies: [
.package(url: "https://github.com/dsmurfin/NWKit", from: "0.0.1")
]
```
