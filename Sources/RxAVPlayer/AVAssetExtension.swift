import AVFoundation
import RxSwift

extension Namespace where Base: AVAsset {
    /// - Note: `AVAsset.loadValuesAsynchronously`が起点
    public var duration: Observable<CMTime> {
        return Observable.create { [weak base] observer in
            base?.loadValuesAsynchronously(forKeys: ["duration"]) {
                if let me = base {
                    observer.onNext(me.duration)
                }
            }

            return Disposables.create()
        }
    }

    /// - Note: `AVAsset.loadValuesAsynchronously`が起点
    public var isPlayable: Observable<Bool> {
        return Observable.create { [weak base] observer in
            base?.loadValuesAsynchronously(forKeys: ["playable"]) {
                if let me = base {
                    observer.onNext(me.isPlayable)
                }
            }

            return Disposables.create()
        }
    }
}
