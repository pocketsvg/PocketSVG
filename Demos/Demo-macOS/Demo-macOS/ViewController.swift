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

        let url = Bundle.main.url(forResource: "iceland", withExtension: "svg")!

        //initialise a view that parses and renders an SVG file in the bundle:
        let svgImageView = SVGImageView.init(contentsOf: url)


        //layout the view:
        svgImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(svgImageView)

        svgImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        svgImageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        svgImageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        svgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
}
