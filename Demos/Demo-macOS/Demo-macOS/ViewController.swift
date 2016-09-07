/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import Cocoa

import PocketSVG

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true

        let url = NSBundle.mainBundle().URLForResource("iceland", withExtension: "svg")!

        //initialise a view that parses and renders an SVG file in the bundle:
        let svgImageView = SVGImageView(contentsOfURL: url)


        //layout the view:
        svgImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(svgImageView)

        svgImageView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        svgImageView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        svgImageView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true
        svgImageView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
    }
}
