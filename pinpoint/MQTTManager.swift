import Foundation
import CocoaMQTT
import UIKit

class MQTTManager: NSObject, ObservableObject, CocoaMQTTDelegate {
    static let shared = MQTTManager()
    private var mqtt: CocoaMQTT?
    @Published var isConnected: Bool = false
    private var isConnecting: Bool = false
    
    private override init() {
        super.init()
    }
    
    func connect() {
        guard !isConnected && !isConnecting else {
            print("[MQTT] Already connected or connecting, skipping connect()")
            return
        }
        isConnecting = true
        let clientID = "test-client"
        let host = "w0b19066.ala.us-east-1.emqxsl.com"
        let port: UInt16 = 8883
        let username = "test-client"
        let password = "test-client"
        print("[MQTT] Attempting connection with:")
        print("  Host: \(host)")
        print("  Port: \(port)")
        print("  ClientID: \(clientID)")
        print("  Username: \(username)")
        print("  Password: \(password)")
        print("  SSL: true")
        let mqtt = CocoaMQTT(clientID: clientID, host: host, port: port)
        mqtt.username = username
        mqtt.password = password
        mqtt.keepAlive = 60
        mqtt.enableSSL = true
        let sslSettings: [String: NSObject] = [
            kCFStreamSSLPeerName as String: "w0b19066.ala.us-east-1.emqxsl.com" as NSObject
        ]
        mqtt.sslSettings = sslSettings
        print("[MQTT] SSL settings applied for SNI.")
        mqtt.autoReconnect = true
        mqtt.delegate = self
        self.mqtt = mqtt
        _ = mqtt.connect()
    }
    
    func disconnect() {
        mqtt?.disconnect()
    }
    
    // MARK: - CocoaMQTTDelegate
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        isConnecting = false
        isConnected = (ack == .accept)
        print("[MQTT] didConnectAck: \(ack)")
        // Subscribe to all test topics
        mqtt.subscribe("test-client/#", qos: .qos1)
        print("[MQTT] Subscribing to topic: test-client/#")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopics success: NSDictionary, failed: [String]) {
        print("[MQTT] didSubscribeTopics: success=\(success), failed=\(failed)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        print("[MQTT] didReceiveMessage: \(message.string ?? "") on topic: \(message.topic), id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("[MQTT] didPublishMessage: \(message.string ?? "") on topic: \(message.topic), id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopics topics: [String]) {
        print("[MQTT] didUnsubscribeTopics: \(topics)")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("[MQTT] mqttDidPing")
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("[MQTT] mqttDidReceivePong")
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        isConnected = false
        isConnecting = false
        print("[MQTT] mqttDidDisconnect with error: \(String(describing: err))")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("[MQTT] didPublishAck for id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        print("[MQTT] State changed to: \(state)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        print("[MQTT] didReceive trust challenge")
        completionHandler(true)
    }
} 
