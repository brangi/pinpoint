import Foundation
import CocoaMQTT
import UIKit

class MQTTManager: NSObject, ObservableObject, CocoaMQTTDelegate {
    static let shared = MQTTManager()
    private var mqtt: CocoaMQTT?
    @Published var isConnected: Bool = false
    private var isConnecting: Bool = false
    private var messageTimer: Timer?
    
    private override init() {
        super.init()
    }
    
    func connect() {
        guard !isConnected && !isConnecting else {
            print("[MQTT] Already connected or connecting, skipping connect()")
            return
        }
        
        
        let username = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let password = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
               
        let clientID: String = {
           var systemInfo = utsname()
            uname(&systemInfo)
           return withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    String(cString: $0)
                }
            }
        }()
        
        
        isConnecting = true
        guard let mqttHost = Bundle.main.object(forInfoDictionaryKey: "MQTT_HOST") as? String else {
            print("[MQTT] Error: MQTT_HOST not found in Info.plist or is not a String.")
            isConnecting = false
            return
        }
        let port: UInt16 = 8883
        print("[clientID] clientID=====c: \(clientID)")
        
        print("[MQTT] Attempting connection with:")
        print("  Host: \(mqttHost)")
        print("  Port: \(port)")
        print("  ClientID: \(clientID)")
        print("  Username: \(username)")
        print("  Password: \(password)")
        print("  SSL: true")
        let mqtt = CocoaMQTT(clientID: clientID, host: mqttHost, port: port)
        mqtt.username = username
        mqtt.password = password
        mqtt.keepAlive = 60
        mqtt.enableSSL = true
        let sslSettings: [String: NSObject] = [
            kCFStreamSSLPeerName as String: mqttHost as NSObject
        ]
        mqtt.sslSettings = sslSettings
        print("[MQTT] SSL settings applied for SNI.")
        mqtt.autoReconnect = true
        mqtt.delegate = self
        self.mqtt = mqtt
        _ = mqtt.connect()
    }
    
    func disconnect() {
        stopMessageTimer()
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
        
        // Start sending periodic messages after successfully subscribing
        if success.count > 0 {
            startMessageTimer()
        }
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
        //print("[MQTT] didReceiveMessage: \(message.string ?? "") on topic: \(message.topic), id: \(id)")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        //print("[MQTT] didPublishMessage: \(message.string ?? "") on topic: \(message.topic), id: \(id)")
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
        stopMessageTimer()
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
    
    // Add a method to publish greeting messages
    func publishGreeting() {
        guard let mqtt = self.mqtt, isConnected else {
            print("[MQTT] Cannot publish greeting: not connected")
            return
        }
        
        // Get the username and client ID from the MQTT client
        let username = mqtt.username ?? "unknown"
        let clientID = mqtt.clientID
        
        // Create a greeting message including username and client ID
        let greetingMessage = [
            "type": "greeting",
            "message": "Hello, this is \(username) connecting with client ID \(clientID)!",
            "username": username,
            "clientID": clientID,
            "timestamp": "\(Date().timeIntervalSince1970)"
        ]
        
        // Convert the message to JSON data
        if let jsonData = try? JSONSerialization.data(withJSONObject: greetingMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            // Publish to the same topic we're subscribed to
            let topic = "test-client/\(clientID)"
            let message = CocoaMQTTMessage(topic: topic, string: jsonString, qos: .qos1)
            mqtt.publish(message)
            
            //print("[MQTT] Published greeting message to topic: \(topic)")
            //print("[MQTT] Greeting content: \(jsonString)")
        } else {
            print("[MQTT] Failed to create greeting message JSON")
        }
    }
    
    // Timer management
    private func startMessageTimer() {
        stopMessageTimer() // Ensure any existing timer is invalidated
        
        // Create a new timer that fires every 5 seconds
        messageTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.publishGreeting()
        }
        
        // Fire immediately for the first message
        publishGreeting()
        
        print("[MQTT] Started periodic message timer (every 5 seconds)")
    }
    
    private func stopMessageTimer() {
        messageTimer?.invalidate()
        messageTimer = nil
        print("[MQTT] Stopped periodic message timer")
    }
} 
