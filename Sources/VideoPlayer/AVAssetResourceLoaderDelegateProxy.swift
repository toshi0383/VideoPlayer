import AVFoundation
import RxCocoa
import RxSwift

public final class AVAssetResourceLoaderDelegateProxy: DelegateProxy<AVAssetResourceLoader, AVAssetResourceLoaderDelegate>, AVAssetResourceLoaderDelegate, DelegateProxyType {

    fileprivate let _loadingRequest = PublishRelay<AVAssetResourceLoadingRequest>()

    public static func registerKnownImplementations() {
        self.register { AVAssetResourceLoaderDelegateProxy($0) }
    }

    public static func currentDelegate(for object: AVAssetResourceLoader) -> AVAssetResourceLoaderDelegate? {
        return object.delegate
    }

    public static func setCurrentDelegate(_ delegate: AVAssetResourceLoaderDelegate?, to object: AVAssetResourceLoader) {
        object.setDelegate(delegate, queue: DispatchQueue(label: ""))
    }

    init(_ object: ParentObject) {
        super.init(parentObject: object, delegateProxy: AVAssetResourceLoaderDelegateProxy.self)
    }

    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let _forwardToDelegate = _forwardToDelegate else {
            fatalError("You MUST call rx.delegate.setForwardToDelegate.")
        }

        if _forwardToDelegate.resourceLoader!(resourceLoader, shouldWaitForLoadingOfRequestedResource: loadingRequest) {
            _loadingRequest.accept(loadingRequest)
            return true
        } else {
            return false
        }
    }

    /// - TODO: Support renewal (fps) as well.
    public func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForRenewalOfRequestedResource renewalRequest: AVAssetResourceRenewalRequest) -> Bool {
        return self.resourceLoader(resourceLoader, shouldWaitForLoadingOfRequestedResource: renewalRequest)
    }
}

extension Reactive where Base: AVAssetResourceLoader {

    public var delegate: DelegateProxy<AVAssetResourceLoader, AVAssetResourceLoaderDelegate> {
        return AVAssetResourceLoaderDelegateProxy.proxy(for: base)
    }

    public var loadingRequest: Observable<AVAssetResourceLoadingRequest> {
        return AVAssetResourceLoaderDelegateProxy.proxy(for: base)._loadingRequest.asObservable()
    }
}
