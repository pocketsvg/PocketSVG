/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import Cocoa
import PocketSVG

@main
class AppDelegate: NSObject, NSApplicationDelegate {}

class DemoController: NSViewController {
    override func loadView() {
        let url = Bundle.main.url(forResource: "iceland", withExtension: "svg")!
        let j = SVGImageView(contentsOf: url)
        print(j.viewBox == .null)
        view = j

        view.frame = NSRect(x: 0, y: 0, width: 300, height: 200)
    }
}
