import UIKit
import MadSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let rootVC = ViewController()
        let navigationController = UINavigationController(rootViewController: rootVC)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        MadsSDK.initialize()
        MadsSDK.isDebugLogsEnabled = true

        return true
    }
}
