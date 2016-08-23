/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import UIKit

import PocketSVG

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .whiteColor()


        //initialise a view that parses and renders an SVG file in the bundle:
        let svgImageView = SVGImageView(SVGNamed: "tiger")


        //scale the resulting image to fit the frame of the view, but
        //maintain its aspect ratio:
        svgImageView.contentMode = .ScaleAspectFit


        //layout the view:
        svgImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(svgImageView)

        svgImageView.topAnchor.constraintEqualToAnchor(view.topAnchor).active = true
        svgImageView.leftAnchor.constraintEqualToAnchor(view.leftAnchor).active = true
        svgImageView.rightAnchor.constraintEqualToAnchor(view.rightAnchor).active = true

    }
}
