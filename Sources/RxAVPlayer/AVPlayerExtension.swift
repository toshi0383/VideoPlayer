import AVFoundation
import RxCocoa
import RxSwift

extension Reactive where Base: AVPlayer {
    /// - NOTE: `play()` / `pause()` はそれぞれ `rate = 1.0` / `rate = 0.0` と同じ.
    ///     `play()` するとrateは1.0に戻り倍速再生が意図せず終わってしまうため、使わないこと.
    var setRate: AnyObserver<Float> {
        return AnyObserver { [weak base] e in
            if let element = e.element {
                base?.rate = element
            }
        }
    }

    var rate: Observable<Float> {
        return base.rx.observe(Float.self, "rate")
            .filterNil()
    }

    /// - Note: `AVPlayer.addPeriodicTimeObserver`が起点
    func periodicTime(for interval: CMTime, queue: DispatchQueue = DispatchQueue.global(qos: .default)) -> Observable<CMTime> {
        return Observable.create { observer in
            let avTimeObserver = self.base.addPeriodicTimeObserver(forInterval: interval, queue: queue) { [observer] time  in
                observer.onNext(time)
            }

            return Disposables.create {
                self.base.removeTimeObserver(avTimeObserver)
            }
        }
    }

    var volume: AnyObserver<Float> {
        return AnyObserver { [weak base] e in
            if let element = e.element {
                base?.volume = element
            }
        }
    }
}
