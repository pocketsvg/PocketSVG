/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if os(visionOS)
        let windowScene = application.connectedScenes.first { $0 is UIWindowScene } as! UIWindowScene
        window = UIWindow(windowScene: windowScene)
        #else
        window = UIWindow(frame: UIScreen.main.bounds)
        #endif
        let rootViewController = UINavigationController(rootViewController: MainViewController())
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()

        return true
    }
}
