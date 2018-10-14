import Foundation

func timeLabel(_ time: Float) -> String {
    let hour = Int(time / (60 * 60))
    let minutes = Int((time / 60).truncatingRemainder(dividingBy: 60))
    let second = Int(time.truncatingRemainder(dividingBy: 60))
    let hourText = hour > 0 ? "\(String(format: "%02d", hour)):" : ""
    return "\(hourText)\(String(format: "%02d", minutes)):\(String(format: "%02d", second))"
}
