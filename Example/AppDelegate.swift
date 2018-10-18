import AVFoundation
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        let vc = ViewController()
        window?.rootViewController = vc
        window?.makeKeyAndVisible()

        if #available(iOS 10.0, *) {
            try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
        } else {
            // -Workaround: https://forums.swift.org/t/using-methods-marked-unavailable-in-swift-4-2/14949
            AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
        }

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
//        try! AVAudioSession.sharedInstance().setActive(true)
    }
}
