//
//  ChainedG.swift
//  CodyFire
//
//  Created by Mihael Isaev on 30/10/2018.
//

import Foundation

public class ChainedG<A: Codable, B: Codable, C: Codable, D: Codable, E: Codable, F: Codable, G: Codable, H: Codable>: Chained {
    public typealias Itself = ChainedG
    public typealias SuccessResponse = (A, B, C, D, E, F, G, H) -> ()
    public typealias SuccessResponseExtended = (ExtendedResponse<A>, ExtendedResponse<B>, ExtendedResponse<C>, ExtendedResponse<D>, ExtendedResponse<E>, ExtendedResponse<F>, ExtendedResponse<G>, ExtendedResponse<H>) -> ()
    public typealias Left = ChainedF<A, B, C, D, E, F, G>
    public typealias Right = APIRequest<H>
    
    let left: Left
    let right: Right
    
    var successHandler: SuccessResponse?
    var successHandlerExtended: SuccessResponseExtended?
    
    init (_ left: Left, _ right: Right) {
        self.left = left
        self.right = right
    }
    
    public func and<I: Codable>(_ next: APIRequest<I>) -> ChainedH<A, B, C, D, E, F, G, H, I> {
        return ChainedH(self, next)
    }
    
    private func configure() {
        if let _ = notAuthorizedCallback {
            left.onNotAuthorized(handleNotAuthorized)
            right.onNotAuthorized(handleNotAuthorized)
        }
        if let _ = progressCallback {
            left.onProgress { p in
                self.handleLeftProgress(p, position: 7)
            }
            right.onProgress { p in
                self.handleRightProgress(p, position: 8)
            }
        }
        if let _ = timeoutCallback {
            left.onTimeout(handleTimeout)
            right.onTimeout(handleTimeout)
        }
        if let _ = cancellationCallback {
            left.onCancellation(handleCancellation)
            right.onCancellation(handleCancellation)
        }
        if let _ = networkUnavailableCallback {
            left.onNetworkUnavailable(handleNetworkUnavailable)
            right.onNetworkUnavailable(handleNetworkUnavailable)
        }
        left.onRequestStarted(handleRequestStarted)
        right.onRequestStarted(handleRequestStarted)
    }
    
    public func onSuccess(_ handler: @escaping SuccessResponse) {
        successHandler = handler
        configure()
        execute()
    }
    
    public func onSuccessExtended(_ handler: @escaping SuccessResponseExtended) {
        successHandlerExtended = handler
        configure()
        execute()
    }
    
    func execute() {
        left.onError(handleError).onSuccessExtended { a, b, c, d, e, f, g in
            self.right.onError(self.handleError).onSuccessExtended { h in
                self.successHandler?(a.body, b.body, c.body, d.body, e.body, f.body, g.body, h.body)
                self.successHandlerExtended?(a, b, c, d, e, f, g, h)
            }
        }
    }
}

extension ChainedG {
    @discardableResult
    public func onError(_ handler: @escaping ErrorResponse) -> Itself {
        errorHandler = handler
        return self
    }
    
    @discardableResult
    public func onNotAuthorized(_ callback: @escaping NotAuthorizedResponse) -> Itself {
        notAuthorizedCallback = callback
        return self
    }
    
    @discardableResult
    public func onProgress(_ callback: @escaping Progress) -> Itself {
        progressCallback = callback
        return self
    }
    
    @discardableResult
    public func onTimeout(_ callback: @escaping TimeoutResponse) -> Itself {
        timeoutCallback = callback
        return self
    }
    
    @discardableResult
    public func onCancellation(_ callback: @escaping TimeoutResponse) -> Itself {
        cancellationCallback = callback
        return self
    }
    
    @discardableResult
    public func onNetworkUnavailable(_ callback: @escaping NetworkUnavailableCallback) -> Itself {
        networkUnavailableCallback = callback
        return self
    }
    
    @discardableResult
    public func onRequestStarted(_ callback: @escaping RequestStartedCallback) -> Itself {
        requestStartedCallback = callback
        return self
    }
}
