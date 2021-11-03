//
//  ContentView.swift
//  GroveNFC Tag
//
//  Created by jens ewald on 23/04/2021.
//

import SwiftUI
import CoreNFC


class NFCReader: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    @Published var scannedData: Data?
    var state = false
    
    func scan() {
        // Look for ISO 15693 tags which the ST M24LRE on the Grove NFC Tag moduel implements
        let session = NFCTagReaderSession(pollingOption: [.iso15693], delegate: self)
        session?.begin()
    }

    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {

    }

    // Handle errors
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        print("Error reading tags", error)
    }

    // Handle scanned tags
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "No tags found.")
            return
        }
        session.connect(to: tag) { (error: Error?) in
                if error != nil {
                    session.invalidate(errorMessage: "Connection error. Please try again.")
                    return
                }

                print("Found tag!")

                switch tag {
                case .iso15693(let discoveredTag):
                    print("Got a ISO 15693 tag!", discoveredTag.icManufacturerCode)
                    print("IC serial number", discoveredTag.icSerialNumber)
                    print("Identifier", discoveredTag.identifier)
                    discoveredTag.extendedReadSingleBlock(requestFlags: .highDataRate, blockNumber: 0x1FFF, completionHandler: { (result: Data, error: Error?) in
                        guard error != nil else {
                            print("error reading single block", error!)
                            return
                        }
                        print(result)
                        let data = Data([self.state ? 0x01 : 0x00])
                        self.state.toggle()
                        discoveredTag.extendedWriteSingleBlock(requestFlags: .highDataRate, blockNumber: 0x1FFF, dataBlock: data) { (error: Error?) in
                            guard error != nil else {
                                print("error writing single block", error!)
                                return
                            }
                        }
                        session.invalidate()
                    })
//                    discoveredTag.writeSingleBlock(requestFlags: .address, blockNumber: 0x07FF, dataBlock: Data) { (error: Error?) in
//                            print("error write single block", error)
//                    }
                    
                case .feliCa(_):
                    return
                case .iso7816(_):
                    return
                case .miFare(_):
                    return
                @unknown default:
                    session.invalidate(errorMessage: "Unsupported tag!")
                }
        }
    }


}

struct ContentView: View {
    let nfc = NFCReader()
    @State private var showAlert = false
    @State var session: NFCTagReaderSession?

    var body: some View {
        VStack {
            Text("Hello, world!").padding()
            Button("Toggle LED", action: {
                guard NFCTagReaderSession.readingAvailable else {
                    showAlert.toggle()
                    return
                }
                
                nfc.scan()
                
            })
        }.alert(isPresented: $showAlert, content: {
            Alert(title: Text("Scanning not supported"),
                  message: Text("This device does not support tag tag scanning"),
                  dismissButton: .cancel())
        })
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
