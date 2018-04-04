/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import UIKit
import PocketSVG

class IcelandicViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let svgURL = Bundle.main.url(forResource: "iceland", withExtension: "svg")!
        let paths = SVGBezierPath.pathsFromSVG(at: svgURL)

        let icelandicView = UIView()
        icelandicView.frame = view.frame
        icelandicView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        for (index, path) in paths.enumerated() {

            // assign different colours to different shapes:
            let shapeLayer = CAShapeLayer()
            shapeLayer.fillColor = UIColor(hue: CGFloat(index)/CGFloat(paths.count), saturation: 1, brightness: 1, alpha: 1).cgColor
            shapeLayer.strokeColor = UIColor(white: 1-CGFloat(index)/CGFloat(paths.count), alpha: 1).cgColor
            shapeLayer.path = path.cgPath
            icelandicView.layer.addSublayer(shapeLayer)

            // animate stroke width:
            let animation = CABasicAnimation(keyPath: "lineWidth")
            animation.toValue = 4
            animation.duration = 1
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            animation.repeatCount = 5
            animation.autoreverses = true
            animation.fillMode = kCAFillModeBoth
            animation.isRemovedOnCompletion = false
            shapeLayer.add(animation, forKey: animation.keyPath)
        }

        // apply transforms to layer to place it within screen bounds:
        var transform = CATransform3DMakeScale(0.4, 0.4, 1.0)
        transform = CATransform3DTranslate(transform, -100, 0, 0)

        icelandicView.layer.transform = transform

        view.addSubview(icelandicView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
}

