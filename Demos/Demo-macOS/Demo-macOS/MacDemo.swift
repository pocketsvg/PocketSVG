/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import Cocoa
import PocketSVG

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {}

class DemoController: NSViewController {
    override func loadView() {
        let url = Bundle.main.url(forResource: "rectangle", withExtension: "svg")!
        let paths = SVGLayer(contentsOf: url).viewBox
        view = SVGImageView(contentsOf: url)
        view.frame = NSRect(x: 0, y: 0, width: 300, height: 200)

    }
}
