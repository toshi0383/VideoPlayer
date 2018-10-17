import UIKit

extension UIControl.Event {
    static var touchUp: UIControl.Event {
        return [.touchUpInside, .touchUpOutside, .touchCancel]
    }
}
