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

        try! AVAudioSession.sharedInstance().objcSetCategory(.playback)

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
//        try! AVAudioSession.sharedInstance().setActive(true)
    }
}
