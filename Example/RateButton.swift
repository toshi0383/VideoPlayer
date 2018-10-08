import RxCocoa
import RxSwift
import UIKit

final class RateButton: UIButton {

    let rate = BehaviorRelay(value: Rate.x1_0)

    var nextRate: Observable<Rate> {
        return rx.tap
            .throttle(1.0, scheduler: ConcurrentMainScheduler.instance)
            .withLatestFrom(rate.asObservable())
            .map { $0.next() }
    }
}

extension RateButton {
    static func make() -> RateButton {
        let button = RateButton(type: .system)

        button.backgroundColor = .lightGray

        button.rate
            .map { $0.string }
            .observeOn(ConcurrentMainScheduler.instance)
            .bind(to: button.rx.title())
            .disposed(by: button.rx.disposeBag)

        return button
    }
}

extension RateButton {

    enum Rate: Float {
        case x1_0 = 1.0
        case x1_5 = 1.5
        case x2_0 = 2.0

        func next() -> Rate {
            let n = self.rawValue + 0.5
            return Rate(rawValue: n > 2.0 ? 1.0 : n)!
        }

        var string: String {
            switch self {
            case .x1_0:
                return "1.0"
            case .x1_5:
                return "1.5"
            case .x2_0:
                return "2.0"
            }
        }
    }

}
