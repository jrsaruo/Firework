# Firework

Firework is a wrapper for [Alamofire](https://github.com/Alamofire/Alamofire).

[![Test](https://github.com/jrsaruo/Firework/actions/workflows/test.yml/badge.svg)](https://github.com/jrsaruo/Firework/actions/workflows/test.yml) [![codecov](https://codecov.io/gh/jrsaruo/Firework/branch/main/graph/badge.svg?token=81ZI7GEBAR)](https://codecov.io/gh/jrsaruo/Firework)

## Requirements

- iOS 10.0+ / macOS 10.12+ / tvOS 10.0+ / watchOS 3.0+
- Xcode 11+
- Swift 5.1+

## Usage

### 1. Define endpoints

```swift
extension Endpoint {
    // Base endpoint
    static var base: Endpoint { "https://some.api.com" }
    
    // Health check API endpoint
    static var healthCheck: Endpoint { base / "health" } // https://some.api.com/health
    
    // User API endpoints
    static var user: Endpoint { base / "user" }
    static var login: Endpoint { user / "login" }
    static var profile: Endpoint { user / "profile" } // https://some.api.com/user/profile
}
```

### 2. Send requests

#### e.g. Send a `GET` request

```swift
// A GET request type
struct HealthCheckRequest: GETRequest {
    var endpoint: Endpoint { .healthCheck }
}

// Send a request [async version]
do {
    let request = HealthCheckRequest()
    let _ = try await HTTPClient().send(request).result.get()
    print("Healthy!")
} catch {
    print(error)
}

// Send a request [callback version]
let request = HealthCheckRequest()
HTTPClient().send(request) { response in
    switch response.result {
    case .success:
        print("Healthy!")
    case .failure(let error):
        print(error)
    }
}
```

#### e.g. Send a `POST` request and decode the response JSON

```swift
// A type corresponding to response JSON such as `{ "name": "...", "age": ... }`
struct Profile: Decodable {
    let name: String
    let age: Int
}

// A POST request type
struct ProfileRequest: POSTRequest, DecodingRequest {
    typealias Response = Profile
    let userID: Int
    
    var endpoint: Endpoint { .profile }
    var body: [String: Any] {
        ["user_id": userID]
    }
}

// Send a request [async version]
do {
    let request = ProfileRequest(userID: 100)
    let profile = try await HTTPClient().send(request).result.get()
    // The type of `profile` is `Profile`
    print("User name:", profile.name)
} catch {
    print(error)
}

// Send a request [callback version]
let request = ProfileRequest(userID: 100)
HTTPClient().send(request, decodingCompletion: { response in
    switch response.result {
    case .success(let profile):
        // The type of `profile` is `Profile`
        print("User name:", profile.name)
    case .failure(let error):
        print(error)
    }
})
```

## Using Firework in your project

To use the `Firework` library in a SwiftPM project, add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/jrsaruo/Firework", from: "3.0.0"),
```

and add `Firework` as a dependency for your target:

```swift
.target(name: "<target>", dependencies: [
    .product(name: "Firework", package: "Firework"),
    // other dependencies
]),
```

Finally, add `import Firework` in your source code.

