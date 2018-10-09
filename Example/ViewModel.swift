import AVFoundation
import VideoPlayerManager
import RxCocoa
import RxSwift

final class ViewModel {

    let playerRelay = PublishRelay<AVPlayer>()
    let rateButtonRate: Property<RateButton.Rate>

    private let _rateButtonRate = BehaviorRelay<RateButton.Rate>(value: .x1_0)

    private let url = URL(string: "https://devstreaming-cdn.apple.com/videos/wwdc/2018/507axjplrd0yjzixfz/507/0640/0640.m3u8")!

    private var manager: VideoPlayerManager!

    private let control = VideoPlayerControl()
    private let disposeBag = DisposeBag()

    init(requestRate: Observable<Float>,
         requestReload: Observable<Void>,
         videoPlayerFactory: VideoPlayerFactoryType = VideoPlayerFactory()) {

        rateButtonRate = Property(_rateButtonRate)

        requestRate
            .bind(to: control.setRate)
            .disposed(by: disposeBag)

        requestReload
            .startWith(()) // NOTE: initial load
            .subscribe(onNext: { [weak self] in
                guard let me = self else { return }

                me.manager = VideoPlayerManager(url: me.url,
                                                control: me.control,
                                                factory: videoPlayerFactory)

                me.manager.objects.append(Something())

                me.manager.player.asObservable()
                    .bind(to: me.playerRelay)
                    .disposed(by: me.manager.playerDisposeBag)

                me.manager.control.setRate
                    .map { RateButton.Rate(rawValue: $0)! }
                    .bind(to: me._rateButtonRate)
                    .disposed(by: me.manager.playerDisposeBag)
            })
            .disposed(by: disposeBag)
    }
}

class Something {
    deinit {
        print("Something is deallocated")
    }
    init() {}
}
