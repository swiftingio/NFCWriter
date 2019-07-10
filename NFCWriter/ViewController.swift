//
//  ViewController.swift
//  NFCWriter
//
//  Created by Bartlomiej Woronin on 03/07/2019.
//  Copyright © 2019 Bartlomiej Woronin. All rights reserved.
//

import UIKit
import CoreNFC
import SwiftUI
import Combine

final class NFCController: UIViewController, BindableObject {
    
    var didChange = PassthroughSubject<Void, Never>()
    var session: NFCNDEFReaderSession?

    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func beginScanning() {
        
        guard NFCNDEFReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "Scanning Not Supported",
                message: "This device doesn't support tag scanning.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        //1
        self.session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead:
            false)
        self.session?.alertMessage = "Hold your iPhone near the item to learn more about it."
        self.session?.begin()
    }
}

extension NFCController: NFCNDEFReaderSessionDelegate {
    
    func tagRemovalDetect(_ tag: NFCNDEFTag) {
        // In the tag removal procedure, you connect to the tag and query for
        // its availability. You restart RF polling when the tag becomes
        // unavailable; otherwise, wait for certain period of time and repeat
        // availability checking.
        self.session?.connect(to: tag) { (error: Error?) in
            if error != nil || !tag.isAvailable {
                
                print("Restart polling")
                
                self.session?.restartPolling()
                return
            }
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .milliseconds(500), execute: {
                self.tagRemovalDetect(tag)
            })
        }
    }
    
    // 2.
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        
        let tag = tags.first!
        // 3
        session.connect(to: tag) { (error: Error?) in
            if error != nil {
                session.restartPolling()
            }
        }

        // 4
        tag.queryNDEFStatus() { (status: NFCNDEFStatus, capacity: Int, error: Error?) in
            
            if error != nil {
                session.invalidate(errorMessage: "Fail to determine NDEF status.  Please try again.")
                return
            }
            
            let textPayload = NFCNDEFPayload.wellKnowTypeTextPayload(string: "Hello from swifting.io", locale: Locale(identifier: "En"))
            let myMessage = NFCNDEFMessage(records: [textPayload!])
        
            if status == .readOnly {
                session.invalidate(errorMessage: "Tag is not writable.")
            } else if status == .readWrite {
                // 5
                tag.writeNDEF(myMessage) { (error: Error?) in
                    if error != nil {
                        session.invalidate(errorMessage: "Update tag failed. Please try again.")
                    } else {
                        session.alertMessage = "Update success!"
                        // 6
                        session.invalidate()
                    }
                }
            } else {
                session.invalidate(errorMessage: "Tag is not NDEF formatted.")
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        //
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        //
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        //
    }
}
