//
//  QRScannerViewModel.swift
//  AirgapKit
//
//  Created by Alex M on 19.02.2026.
//
import Airgap

final class QRScannerViewModel: ChangeNotifier {
    var state: ScannerState = .idle {
        didSet {
            notifyListeners()
        }
    }
    
    var scannedChunks: Set<Int> = []
    var totalChunks: Int   = 0
    var progress: Double   = 0.0

    private var decoder: AGDecoder?

    override init() {
        super.init()
        decoder = AGDecoder()
    }

    func startScanning() {
        state         = .scanning
        scannedChunks = []
        totalChunks   = 0
        progress      = 0.0
        decoder       = AGDecoder()
    }

    func processQRCode(_ code: String) {
        guard case .scanning = state, let decoder = decoder else { return }

        do {
            let result = try decoder.processQRString(code)

            scannedChunks.insert(Int(result.chunkNumber))
            totalChunks   = Int(result.totalChunks)

            if totalChunks > 0 {
                progress = Double(scannedChunks.count) / Double(totalChunks)
            }
            notifyListeners()

            if decoder.isComplete {
                state = .processing
                completeScanning()
            }
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    private func completeScanning() {
        guard let decoder = decoder else {
            state = .error("Decoder not initialized")
            return
        }
        do {
            let data = try decoder.getData()
            state = .success(data)
        } catch {
            state = .error("Failed to decode data: \(error.localizedDescription)")
        }
    }

    func reset() {
        state         = .idle
        scannedChunks = []
        totalChunks   = 0
        progress      = 0.0
        decoder       = AGDecoder()
    }
}
