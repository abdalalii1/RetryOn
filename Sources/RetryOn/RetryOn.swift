import Combine

public extension Publishers {
    
    struct RetryOn<Upstream: Publisher, ErrorType: Error & Equatable>: Publisher {
        
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure
        
        let upstream: Upstream
        let retries: UInt
        let error: ErrorType
        let chainedPublisher: AnyPublisher<Output, Failure>?
        
        /// Creates a publisher that attempts to recreate its subscription to a failed upstream publisher.
        ///
        /// - Parameters:
        ///   - upstream: The publisher from which this publisher receives its elements.
        ///   - error: An equatable error that should trigger the retry
        ///   - retries: The number of times to attempt to recreate the subscription.
        ///   - chainedPublisher: An optional publisher of the same type, to chain before the retry
        init(upstream: Upstream, retries: UInt, error: ErrorType, chainedPublisher: AnyPublisher<Output, Failure>?) {
            self.upstream = upstream
            self.retries = retries
            self.error = error
            self.chainedPublisher = chainedPublisher
        }
        
        public func receive<S: Subscriber>(subscriber: S) where Upstream.Failure == S.Failure, Upstream.Output == S.Input {
            self.upstream
                .catch { e -> AnyPublisher<Output, Failure> in
                    guard (e as? ErrorType) == self.error, self.retries > 0 else {
                        return Fail<Output, Failure>(error: e).eraseToAnyPublisher()
                    }
                    
                    if let chainedPublisher = self.chainedPublisher {
                        return chainedPublisher
                            .flatMap { value -> AnyPublisher<Output, Failure> in
                                self.upstream.retryOn(self.error, retries: self.retries - 1).eraseToAnyPublisher()
                            }
                            .eraseToAnyPublisher()
                    }
                    
                    return self.upstream.retryOn(self.error, retries: self.retries - 1).eraseToAnyPublisher()
                }
                .subscribe(subscriber)
        }
    }
}

public extension Publisher {
    /// Attempts to recreate a failed subscription with the upstream publisher using a specified number of attempts.
    ///
    /// After exceeding the specified number of retries, the publisher passes the failure to the downstream receiver.
    /// - Parameter error: An equatable error that should trigger the retry
    /// - Parameter retries: The number of times to attempt to recreate the subscription.
    /// - Parameter chainedPublisher: An optional publisher of the same type, to chain before the retry
    /// - Returns: A publisher that attempts to recreate its subscription to a failed upstream publisher.
    func retryOn<E: Error & Equatable>(
        _ error: E,
        retries: UInt,
        chainedPublisher: AnyPublisher<Output, Failure>? = nil
    ) -> Publishers.RetryOn<Self, E> {
        return .init(upstream: self,
                     retries: retries,
                     error: error,
                     chainedPublisher: chainedPublisher)
    }
}
