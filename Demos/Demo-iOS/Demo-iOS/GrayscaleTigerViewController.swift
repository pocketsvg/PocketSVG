/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import PocketSVG
import UIKit

class GrayscaleTigerViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        let svgURL = Bundle.main.url(forResource: "tiger", withExtension: "svg")!
        let paths = SVGBezierPath.pathsFromSVG(at: svgURL)

        let tigerLayer = CALayer()

        for (index, path) in paths.enumerated() {
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = path.cgPath

            if index % 2 == 0 {
                shapeLayer.fillColor = UIColor.black.cgColor
            } else if index % 3 == 0 {
                shapeLayer.fillColor = UIColor.darkGray.cgColor
            } else {
                shapeLayer.fillColor = UIColor.gray.cgColor
            }

            tigerLayer.addSublayer(shapeLayer)
        }

        var transform = CATransform3DMakeScale(0.4, 0.4, 1.0)
        transform = CATransform3DTranslate(transform, 200, 400, 0)

        tigerLayer.transform = transform
        view.layer.addSublayer(tigerLayer)
    }
}
