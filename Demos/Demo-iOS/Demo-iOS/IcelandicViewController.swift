/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import PocketSVG
import UIKit

class IcelandicViewController: UIViewController {
    let icelandicView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        let svgURL = Bundle.main.url(forResource: "iceland", withExtension: "svg")!
        let paths = SVGBezierPath.pathsFromSVG(at: svgURL)

        for (index, path) in paths.enumerated() {
            // assign different colours to different shapes:
            let shapeLayer = CAShapeLayer()
            shapeLayer.fillColor = UIColor(hue: CGFloat(index) / CGFloat(paths.count), saturation: 1, brightness: 1, alpha: 1).cgColor
            shapeLayer.strokeColor = UIColor(white: 1 - CGFloat(index) / CGFloat(paths.count), alpha: 1).cgColor
            shapeLayer.path = path.cgPath
            icelandicView.layer.addSublayer(shapeLayer)

            // animate stroke width:
            let animation = CABasicAnimation(keyPath: "lineWidth")
            animation.toValue = 4
            animation.duration = 1
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animation.repeatCount = 5
            animation.autoreverses = true
            animation.fillMode = CAMediaTimingFillMode.both
            animation.isRemovedOnCompletion = false
            shapeLayer.add(animation, forKey: animation.keyPath)
        }

        let r = SVGBoundingRectForPaths(paths)
        icelandicView.frame = r

        let scrollview = UIScrollView(frame: view.bounds)
        scrollview.maximumZoomScale = 5.0
        scrollview.minimumZoomScale = 0.5

        scrollview.contentSize = r.size

        scrollview.delegate = self

        scrollview.addSubview(icelandicView)

        view.addSubview(scrollview)
    }
}

extension IcelandicViewController: UIScrollViewDelegate {
    func viewForZooming(in _: UIScrollView) -> UIView? {
        icelandicView
    }
}
