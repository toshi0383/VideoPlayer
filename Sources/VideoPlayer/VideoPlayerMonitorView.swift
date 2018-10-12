import AVFoundation
import RxCocoa
import RxSwift

/// A transparent view which displays infomations from VideoPlayerMonitor.
public class VideoPlayerMonitorView: UIView {

    private let textView = UITextView()
    private var monitorDisposeBag = DisposeBag()

    public var monitor: VideoPlayerMonitor? {
        didSet {
            monitorDisposeBag = DisposeBag()
            textView.text = nil

            monitor?.consoleString
                .bind(to: textView.rx.text)
                .disposed(by: monitorDisposeBag)
        }
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if superview == nil {
            monitor = nil
            return
        }

        textView.isEditable = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        textView.textColor = .white
        addSubview(textView)

        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: textView.topAnchor),
            leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            heightAnchor.constraint(equalTo: textView.heightAnchor),
            widthAnchor.constraint(equalTo: textView.widthAnchor),
        ])
    }
}
