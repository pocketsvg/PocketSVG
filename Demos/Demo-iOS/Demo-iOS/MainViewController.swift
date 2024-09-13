/*
 * This file is part of the PocketSVG package.
 * Copyright (c) Ponderwell, Ariel Elkin, Fjölnir Ásgeirsson, and Contributors
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

import UIKit

class MainViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "PocketSVG Demo"

        let tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "identifier")
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }
}

enum Section: Int {
    case simple
    case complex

    var title: String {
        switch self {
        case .simple:
            "Simple"
        case .complex:
            "Complex"
        }
    }

    static var count: Int {
        2
    }
}

enum SimpleRow: Int {
    case circle
    case curve
    case lines
    case attribute_inheritance
    case iceland
    case tiger

    static var count: Int {
        4
    }

    var svgURL: URL {
        switch self {
        case .circle:
            Bundle.main.url(forResource: "circle", withExtension: "svg")!
        case .curve:
            Bundle.main.url(forResource: "curve", withExtension: "svg")!
        case .lines:
            Bundle.main.url(forResource: "lines", withExtension: "svg")!
        case .attribute_inheritance:
            Bundle.main.url(forResource: "attribute_inheritance", withExtension: "svg")!
        case .iceland:
            Bundle.main.url(forResource: "iceland", withExtension: "svg")!
        case .tiger:
            Bundle.main.url(forResource: "tiger", withExtension: "svg")!
        }
    }

    var title: String {
        switch self {
        case .circle:
            "Circle"
        case .curve:
            "Curve"
        case .lines:
            "Lines"
        case .attribute_inheritance:
            "Attribute Inheritance"
        case .iceland:
            "Iceland"
        case .tiger:
            "Tiger"
        }
    }
}

enum ComplexRow: Int {
    case rectangle
    case icelandic
    case grayscaleTiger

    static var count: Int {
        3
    }

    var title: String {
        switch self {
        case .rectangle:
            "Rectangle"
        case .icelandic:
            "Icelandic"
        case .grayscaleTiger:
            "Grayscale Tiger"
        }
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "identifier", for: indexPath)

        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .simple:
            let row = SimpleRow(rawValue: indexPath.row)!
            cell.textLabel?.text = row.title
        case .complex:
            let row = ComplexRow(rawValue: indexPath.row)!
            cell.textLabel?.text = row.title
        }

        return cell
    }

    func numberOfSections(in _: UITableView) -> Int {
        Section.count
    }

    func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionEnum = Section(rawValue: section)!
        switch sectionEnum {
        case .simple:
            return SimpleRow.count
        case .complex:
            return ComplexRow.count
        }
    }

    func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionEnum = Section(rawValue: section)!
        return sectionEnum.title
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!

        switch section {
        case .simple:
            let row = SimpleRow(rawValue: indexPath.row)!
            let svgURL = row.svgURL
            let detailVC = SimpleDetailViewController(svgURL: svgURL)
            navigationController?.pushViewController(detailVC, animated: true)

        case .complex:
            let row = ComplexRow(rawValue: indexPath.row)!
            let vc: UIViewController = switch row {
            case .rectangle:
                RectangleViewController()
            case .icelandic:
                IcelandicViewController()
            case .grayscaleTiger:
                GrayscaleTigerViewController()
            }
            navigationController?.pushViewController(vc, animated: true)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
