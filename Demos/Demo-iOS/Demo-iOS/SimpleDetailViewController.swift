//
//  DetailViewController.swift
//  Demo-iOS
//
//  Created by Ariel Elkin on 04/04/2018.
//  Copyright © 2018 PocketSVG. All rights reserved.
//

import UIKit
import PocketSVG

class SimpleDetailViewController: UIViewController {

    init(svgURL: URL) {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .white

        let svgImageView = SVGImageView.init(contentsOf: svgURL)

        svgImageView.frame = view.bounds
        svgImageView.contentMode = .scaleAspectFit
        svgImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(svgImageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
