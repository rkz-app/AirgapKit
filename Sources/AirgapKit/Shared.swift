//
//  Shard.swift
//  AirgapKit
//
//  Created by Alex M on 18.02.2026.
//


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
