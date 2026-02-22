//
//  QRPlayerViewModel.swift
//  AirgapKit
//
//  Created by Alex M on 18.02.2026.
//

import Airgap
import Foundation
import UIKit

enum ViewModelState: Equatable {
    case initial
    case buildingQR
    case qrError(String)
    case pause
    case playing
}

enum ViewModelError: Error {
    case incompleteGeneration
}


public class QRPlayerViewModel: ChangeNotifier {
        
    
    
    var state: ViewModelState = .initial {
        didSet {
            if oldValue != state {
                notifyListeners()
            }
        }
    }
    
    var currentIndex = 0
    
    var images: [UIImage] = []
    
    private let data: Data
    
    var chunkSize: UInt = 460
    
    var totalChunks: UInt = 0
    
    init(data: Data) {
        self.data = data
    }
    
    var playButtonState: PlayButtonState {
        switch state {
        case .pause:
            return isLastIndex  ? PlayButtonState.replay : PlayButtonState.play
        case .playing:
            return .pause
        default:
            return .play
        }
    }
    
    
    func assemble() {
        state = .buildingQR
        assembleQRs {[weak self] result in
            guard let self = self else {
                return 
            }
            switch result {
            case .success(let images) :
                self.images = images;
                self.state = .pause
            case .failure(let err):
                self.state = .qrError(err.localizedDescription)
            }
        }
    }
    
    func forward() {
        currentIndex =
            min(images.count - 1, currentIndex + 1)
        notifyListeners()
    }
    
    func backward() {
        currentIndex = max(0, currentIndex - 1)
        notifyListeners()
    }
    
    var isPlaying: Bool {
        return state == .playing
    }
    
    private func assembleQRs(callback: @escaping (Result<[UIImage], Error>) -> Void) {
        do {
            let encoder = try AGEncoder(data: data, chunkSize: chunkSize, qrSize: 700)
            let count = encoder.chunkCount
            totalChunks = count
            

            final class ThreadSafeResults: @unchecked Sendable {
                private var storage: [Data?]
                private let lock = NSLock()
                init(count: Int) { self.storage = Array(repeating: nil, count: count) }
                func set(_ data: Data, at index: Int) {
                    lock.lock(); defer { lock.unlock() }
                    storage[index] = data
                }
                func snapshot() -> [Data?] {
                    lock.lock(); defer { lock.unlock() }
                    return storage
                }
            }

            let resultsBox = ThreadSafeResults(count: Int(count))
            
            let group = DispatchGroup()
            
            let queue = DispatchQueue.global(qos: .userInitiated)
            
            
            for i in 0..<count {
                group.enter()
                queue.async {
                    do {
                        let data = try encoder.generatePNG(at: i)
                        resultsBox.set(data, at: Int(i))
                    } catch {
                        
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                let results = resultsBox.snapshot()
                if results.contains(where: { $0 == nil }) {
                    callback(.failure(ViewModelError.incompleteGeneration))
                } else {
                    let images: [UIImage] = results.compactMap { data in
                        guard let data else { return nil }
                        return UIImage(data: data)
                    }
                    callback(.success(images))
                }
            }
        } catch (let e) {
            callback(.failure(e))
        }
    }
    
    var isLastIndex: Bool {
        return currentIndex == images.count - 1
    }
    
    func play() {
        guard !images.isEmpty else { return }
        if isLastIndex {
            currentIndex = 0
        }
        state = .playing
    }
    
    func pause() {
        state = .pause
    }
    
    func nextFrame() {
        guard !images.isEmpty else { return }
        if currentIndex < images.count - 1 {
            currentIndex += 1
        } else {
            // Reached the end, pause
            state = .pause
        }
    }
}

