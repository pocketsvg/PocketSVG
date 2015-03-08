//
//  ViewController.swift
//  PocketSVG iOS Example
//
//  Created by Ariel Elkin on 08/03/2015.
//  Copyright (c) 2015 Arielito. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        //1: Turn your SVG into a CGPath:
        let myPath = PocketSVG.pathFromSVGFileNamed("BezierCurve1").takeUnretainedValue()


        //2: To display it on screen, you can create a CAShapeLayer
        //and set myPath as its path property:
        let myShapeLayer = CAShapeLayer()
        myShapeLayer.path = myPath


        //3: Fiddle with it using CAShapeLayer's properties:
        myShapeLayer.strokeColor = UIColor.redColor().CGColor
        myShapeLayer.lineWidth = 3
        myShapeLayer.fillColor = UIColor.clearColor().CGColor


        //4: Display it!
        self.view.layer.addSublayer(myShapeLayer)


        //Make it smaller if we're on an iPhone:
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            myShapeLayer.transform = CATransform3DMakeScale(0.3, 0.3, 0.3)
        }
    }
}

