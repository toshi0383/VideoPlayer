import AVFoundation
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
         requestReload: Observable<Void>) {

        requestRate
            .bind(to: control.setRate)
            .disposed(by: disposeBag)

        rateButtonRate = Property(_rateButtonRate)

        requestReload
            .startWith(())
            .subscribe(onNext: { [weak self] in
                guard let me = self else { return }
                me.manager = VideoPlayerManager(url: me.url, control: me.control)

                me.manager.player.asObservable()
                    .bind(to: me.playerRelay)
                    .disposed(by: me.disposeBag)

                me.manager.monitor.rate
                    .map { RateButton.Rate(rawValue: $0) }
                    .filterNil()
                    .bind(to: me._rateButtonRate)
                    .disposed(by: me.disposeBag)
            })
            .disposed(by: disposeBag)
    }
}
