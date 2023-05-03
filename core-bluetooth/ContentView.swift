import SwiftUI
import CoreBluetooth

class PeripheralManager: NSObject, CBPeripheralManagerDelegate, ObservableObject {
    
    @Published var peripheralManager: CBPeripheralManager!
    @Published var characteristic: CBMutableCharacteristic!
    @Published var service: CBMutableService!
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        if peripheral.state == .poweredOn {
            print("Peripheral Manager is powered on")
            
            let uuid = CBUUID(string: "D9D9D9FB-8C28-4C5E-94E9-58C23B7C69E2")
            self.characteristic = CBMutableCharacteristic(type: uuid, properties: .read, value: Data([0xD9]), permissions: .readable)
            //self.characteristic.value = Data([0xD9]) // Set characteristic value to D9D9
            
            self.service = CBMutableService(type: uuid, primary: true)
            self.service.characteristics = [self.characteristic]
            
            self.peripheralManager.add(self.service)
        } else {
            print("Peripheral Manager is not powered on")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("Error adding service: \(error.localizedDescription)")
            return
        }
        print("Service added with UUID: \(service.uuid.uuidString)")
        
        self.peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[self.service.uuid]])
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Error advertising: \(error.localizedDescription)")
            return
        }
        print("Advertising started")
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        print("Received Write Request")
        
        for request in requests {
            if request.characteristic.uuid == self.characteristic.uuid {
                if let value = request.value {
                    let userDetails = String(data: value, encoding: .utf8)
                    print("Received User Details: \(userDetails ?? "")")
                }
            }
        }
        self.peripheralManager.respond(to: requests[0], withResult: .success)
    }
    
    func start() {
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func writeUserDetails(userDetails: String) {
        let userDetailsData = userDetails.data(using: .utf8)
        
        self.characteristic.value = userDetailsData
        
        self.peripheralManager.updateValue(userDetailsData!, for: self.characteristic, onSubscribedCentrals: nil)
    }
}

struct ContentView: View {
    @StateObject var peripheralManager = PeripheralManager()
    
    var body: some View {
        Text("Peripheral Hello, World!")
            .onAppear {
                peripheralManager.start()
            }
            .onTapGesture {
                peripheralManager.writeUserDetails(userDetails: "9D9")
            }
    }
}
