/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import PocketSVG
import UIKit

class RectangleViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let svgURL = Bundle.main.url(forResource: "rectangle", withExtension: "svg")!

        let svgImageView = SVGImageView(contentsOf: svgURL)

        // The original SVG's stroke color is yellow, but we'll make it red:
        svgImageView.strokeColor = .red

        // The original SVG's fill is transparent but we'll make it blue:
        svgImageView.fillColor = .blue

        svgImageView.frame = view.bounds
        svgImageView.contentMode = .scaleAspectFit
        svgImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(svgImageView)
    }
}
