//
//  SimpleDetailViewController.swift
//  Demo-iOS
//
//  Created by Ariel Elkin on 04/04/2018.
//  Copyright © 2018 PocketSVG. All rights reserved.
//

import PocketSVG
import UIKit

class SimpleDetailViewController: UIViewController {
    init(svgURL: URL) {
        super.init(nibName: nil, bundle: nil)

        view.backgroundColor = .white

        let svgImageView = SVGImageView(contentsOf: svgURL)
        svgImageView.contentMode = .scaleAspectFit

        view.addSubview(svgImageView)
        svgImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            svgImageView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 12),
            svgImageView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -12),
            svgImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            svgImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ]
        )
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
