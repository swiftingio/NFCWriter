//
//  ContentView.swift
//  NFCWriter
//
//  Created by Bartlomiej Woronin on 04/07/2019.
//  Copyright © 2019 Bartlomiej Woronin. All rights reserved.
//

import Foundation
import SwiftUI
import CoreNFC

struct ContentView: View {
    
    @EnvironmentObject var nfcController: NFCController
    
    var body: some View {
        VStack {
            Button(action: {
                self.nfcController.beginScanning()
            }) {
                Text("Write to TAG")
                }.padding(.all)
        }
    }
}
