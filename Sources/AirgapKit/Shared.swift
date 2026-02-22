//
//  Shard.swift
//  AirgapKit
//
//  Created by Alex M on 18.02.2026.
//

import UIKit


typealias VoidCallback = () -> Void


public class ChangeNotifier {
    
    var listeners: [VoidCallback] = []
    
    func addListener(callback:@escaping VoidCallback) {
        listeners.append(callback)
    }
    
    func notifyListeners() {
        for listener in listeners {
            listener()
        }
    }
}

enum Palette {
    static let blue  = UIColor(red: 0.00, green: 0.48, blue: 1.00, alpha: 1)
    static let green = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
    static let red   = UIColor(red: 1.00, green: 0.23, blue: 0.19, alpha: 1)
    static let gray  = UIColor(white: 0.6, alpha: 1)
}


extension UILabel {
    static func make(
        text: String       = "",
        size: CGFloat,
        weight: UIFont.Weight = .regular,
        color: UIColor        = UIColor(white: 0.1, alpha: 1),
        alignment: NSTextAlignment = .center,
        lines: Int            = 0
    ) -> UILabel {
        let l           = UILabel()
        l.text          = text
        l.font          = UIFont.systemFont(ofSize: size, weight: weight)
        l.textColor     = color
        l.textAlignment = alignment
        l.numberOfLines = lines
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }
}


final class FilledButton: UIButton {

    private var handler: (() -> Void)?

    init(title: String, color: UIColor) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font  = UIFont.systemFont(ofSize: 16, weight: .semibold)
        backgroundColor   = color
        layer.cornerRadius = 14
        clipsToBounds     = true
        contentEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
        addTarget(self, action: #selector(didTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func onTap(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc private func didTap() {
        handler?()
    }
}

