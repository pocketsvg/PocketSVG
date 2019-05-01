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
        svgImageView.contentMode = .scaleAspectFit

        view.addSubview(svgImageView)
        svgImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            svgImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 12),
            svgImageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
            svgImageView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: 12),
            svgImageView.bottomAnchor.constraint(equalTo: bottomLayoutGuide.topAnchor, constant: -12),
            ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
