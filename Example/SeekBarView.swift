import RxCocoa
import RxSwift
import VideoPlayer
import UIKit

final class SeekBarView: UIView {
    let stackView = UIStackView()
    let slider = UISlider()
    let totalTimeLabel = UILabel()
    let currentTimeLabel = UILabel()
}

extension SeekBarView {

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if superview == nil {
            return
        }

        // MARK: Layout: self

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 40),
        ])

        // MARK: Layout: stackView

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 5
        addSubview(stackView)

        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            heightAnchor.constraint(equalTo: stackView.heightAnchor),
        ])

        // MARK: Layout: currentTimeLabel

        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        currentTimeLabel.textColor = .white
        stackView.addArrangedSubview(currentTimeLabel)

        // MARK: Layout: slider

        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.tintColor = .white
        slider.minimumTrackTintColor = .white
        slider.maximumTrackTintColor = .gray
        stackView.addArrangedSubview(slider)

        // MARK: Layout: totalTimeLabel

        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTimeLabel.textColor = .white
        stackView.addArrangedSubview(totalTimeLabel)
    }

}
