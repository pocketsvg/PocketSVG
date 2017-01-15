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
        let url = Bundle.main.url(forResource: "iceland", withExtension: "svg")!
        view = SVGImageView.init(contentsOf: url)
    }
}
