# RetryOn

The RetryOn makes it simple for subscribers to retry and run a stream upon a failure.

# Usage

Ensure to import RetryOn in each file you wish to have access to the utility.

The operator can be then used as part of your usual publisher chain declaration:

```swift
let _ = publisher.retryOn(ErrorName, retries: 1, chainedPublisher: useThisPublisherBeforeRetrying)
```

# Installation

Swift Package Manager:

```swift
dependencies: [
	.package(url: "https://github.com/abdalaliii/RetryOn.git")
]
```

## License

**RetryOn** is available under the MIT license. See the LICENSE file for more info.
