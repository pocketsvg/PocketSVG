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

        view.backgroundColor = .white

        let url = Bundle.main.url(forResource: "tiger", withExtension: "svg")!

        //initialise a view that parses and renders an SVG file in the bundle:
        let svgImageView = SVGImageView.init(contentsOf: url)


        //scale the resulting image to fit the frame of the view, but
        //maintain its aspect ratio:
        svgImageView.contentMode = .scaleAspectFit


        //layout the view:
        svgImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(svgImageView)

        svgImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        svgImageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        svgImageView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
    }
}
