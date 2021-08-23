import UIKit



var stringAMX : String? = nil

public class CherryAgent{
            
    private  var consumerKey : String? = nil
    
    private  var appDelegate : UIApplication? = nil
    
    private var topicListener : CherryTopicListener? = nil
    
    private var domain = "https://apib-kwt.almullaexchange.com/xms"
    
    private var isDebug = false
    
    var batteryState: UIDevice.BatteryState {
       return UIDevice.current.batteryState
    }
    
    public init(appDelegate : UIApplication){
        self.appDelegate = appDelegate
        
    }
    
    public  func setConsumerKey(consumerKey : String, topicListener : CherryTopicListener) -> CherryAgent{
        self.consumerKey = consumerKey
        self.topicListener = topicListener
        UserDefaults.standard.set(consumerKey, forKey: "consumerKey")
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        print("APP VERSION : "+appVersion!)
        UserDefaults.standard.set(appVersion, forKey: "appVersion")
        
        
        
        let os = ProcessInfo.processInfo.operatingSystemVersion
        print("OS VERSION : "+String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion))
        UserDefaults.standard.set(String(os.majorVersion) + "." + String(os.minorVersion) + "." + String(os.patchVersion), forKey: "osVersion")
        print("CLIENT FP : "+UIDevice.current.identifierForVendor!.uuidString)
        
        
        
        return self
    }
    
//    public func setDebug(debug : Bool) -> CherryAgent{
//        isDebug = debug
//        return self
//    }
    
    public func set(domain : String){
        self.domain = domain
        UserDefaults.standard.set(domain, forKey: "domain")
        makeHeartbeatApiCall()
    }
    
    
    
    private  func makeHeartbeatApiCall(){
        let consumerKey = UserDefaults.standard.string(forKey: "consumerKey")
        let appVersion = UserDefaults.standard.string(forKey: "appVersion")
        let osVersion = UserDefaults.standard.string(forKey: "osVersion")
        let clientFP = UIDevice.current.identifierForVendor!.uuidString
        
        
        var encodedString = ""
        
        if let savedEncodedString = UserDefaults.standard.string(forKey: "signature"){
            encodedString = savedEncodedString
        }
        
//        let userAgent = NSMutableDictionary()
//
//        userAgent["appType"] = "IOS"
//        userAgent["channel"] = "IOS"
//        userAgent["devicePlatform"] = "IOS"
//        userAgent["deviceType"] = "MOBILE"
        
        
        let uuid = NSMutableDictionary()
        if UserDefaults.standard.integer(forKey: "uuidVersion") != 0{
            if let uuidValue = UserDefaults.standard.string(forKey: "uuidValue"){
                if UserDefaults.standard.integer(forKey: "uuidUpdateTimeStamp") != 0{
                    uuid["version"] = UserDefaults.standard.integer(forKey: "uuidVersion")
                    uuid["value"] = uuidValue
                    uuid["updatedStamp"] = UserDefaults.standard.integer(forKey: "uuidUpdateTimeStamp")
                }
            }
        }else{
            uuid["version"] = 0
            uuid["value"] = ""
            uuid["updatedStamp"] = 0
        }
        
        
        
        var params = NSMutableDictionary()
        
        let clientProperties = NSMutableDictionary()
        clientProperties["appVersion"] = appVersion
        clientProperties["osVersion"] = osVersion
        clientProperties["appType"] = "IOS"
        clientProperties["channel"] = "IOS"
        clientProperties["devicePlatform"] = "IOS"
        clientProperties["deviceType"] = "MOBILE"
        
        
        
        params = ["clientFp" : clientFP as Any,"signature" : encodedString as Any]
        
        if let clientID = UserDefaults.standard.string(forKey: "clientId"){
            params["clientId"] = clientID
        }
        
        if let identity = UserDefaults.standard.string(forKey: "identity"){
            params["identity"] = identity
        }
        
        params["clientProperties"] = clientProperties
        params["uuId"] = uuid
        
        do{
            let jsonData: Data = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted)
            print(NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String)
        }catch{
            print(error)
        }
        

        var request = URLRequest(url: URL(string: domain+"/api/v1/client/heartbeat")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(consumerKey!, forHTTPHeaderField: "consumerKey")

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                print(json)
                if let resultArray = json["results"] as? NSArray{
                    if let resultDictionary = resultArray[0] as? NSDictionary{
                        print("IN DICT ")
                        if let clientId = resultDictionary.object(forKey: "clientId") as? String{
                            print("ClientID "+clientId)
                            UserDefaults.standard.set(clientId, forKey: "clientId")
                        }
                        
                        if(self.topicListener != nil){
                            self.topicListener!.onTopicReceived(topic: "topic_cherry_amiec")
                        }
                        
                        if let uuidDictionary = resultDictionary.object(forKey: "uuId") as? NSDictionary{
                            print("IN DICT UUID")
                            if let value = uuidDictionary.object(forKey: "value") as? String{
                                UserDefaults.standard.set(value, forKey: "uuidValue")
                            }
                            
                            if let version = uuidDictionary.object(forKey: "version") as? Int{
                                UserDefaults.standard.set(version, forKey: "uuidVersion")
                            }
                            
                            if let updatedStamp = uuidDictionary.object(forKey: "updatedStamp") as? Double{
                                UserDefaults.standard.set(updatedStamp, forKey: "uuidUpdateTimeStamp")
                            }
                        }
                        
                        if let value = resultDictionary.object(forKey: "signature") as? String{
                            UserDefaults.standard.set(value, forKey: "signature")
                        }
                    }
                }
                
            } catch {
                print("error")
            }
        })

        task.resume()
    }
    
    
    
    
    
    static public func setEvent(event : Event,response:@escaping(Result) -> Void){
        let consumerKey = UserDefaults.standard.string(forKey: "consumerKey")
        let params = NSMutableDictionary()
        let eventData = NSMutableDictionary()
        eventData["attr"] = event.attr
        eventData["data"] = event.data
        params["eventData"] = eventData
        params["eventName"] = event.eventName
        
        
//        let links = NSMutableArray()
//        if let identity = UserDefaults.standard.string(forKey: "identity"){
//            let link = NSMutableDictionary()
//            link["linkName"] = "identity"
//            link["linkType"] = "CUSTOMER"
//            link["linkValue"] = identity
//            links.add(link)
//        }
        
//        let clientFP = UIDevice.current.identifierForVendor!.uuidString
        
//        let link = NSMutableDictionary()
//        link["linkName"] = "clientFp"
//        link["linkType"] = "DEVICE"
//        link["linkValue"] = clientFP
//
//        links.add(link)
//
//        params["links"] = links
        
        
        do{
            let jsonData: Data = try JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted)
            print(NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String)
        }catch{
            print(error)
        }
        var domain = UserDefaults.standard.string(forKey: "domain")
        
        if domain == nil{
            domain = "https://apib-kwt.almullaexchange.com/xms"
        }
        var request = URLRequest(url: URL(string: domain!+"/api/v1/client/track/event")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let clientID = UserDefaults.standard.string(forKey: "clientId"){
            request.addValue(clientID, forHTTPHeaderField: "clientId")
        }
        request.addValue(consumerKey!, forHTTPHeaderField: "consumerKey")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            print(response!)
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                print(json)
            } catch {
                print("error")
            }
        })

        task.resume()
    }
    
    static public func setNotifier(userInfo: [AnyHashable: Any]){
        print("NOTIFIER NOTIFIED")
        
    }
}

public class Event{
    var eventName : String? = nil
    var attr : [String : Any]? = nil
    var data : [String : Any]? = nil
    
    
    public init(eventName : String) {
        self.eventName = eventName
    }
    
    
    public func setAttributes(attr : [String : Any]) -> Event{
        self.attr = attr
        return self
    }
    
    public func setData(data : [String : Any]) -> Event{
        self.data = data
        return self
    }
    
    public func send(response:@escaping(Result) -> Void) {
        CherryAgent.setEvent(event: self,response: response)
    }
    
    public func send() {
        CherryAgent.setEvent(event: self,response: {
            response in
            if(response.status == "Success"){
                
            }else{
                
            }
        })
    }
    
    
}

public class Result{
    public var status : String? = nil
    
    init(status : String) {
        self.status = status
    }
}


private struct InitModel: Codable {
    var appID, appKey, appVersion, clientFP: String?
    var clientID, identity, ipAddress, osVersion: String?
    var userAgent: UserAgent?
    var uuID: UuID?

    enum CodingKeys: String, CodingKey {
        case appID = "appId"
        case appKey, appVersion
        case clientFP = "clientFp"
        case clientID = "clientId"
        case identity, ipAddress, osVersion, userAgent
        case uuID = "uuId"
    }
}

// MARK: - UserAgent
struct UserAgent: Codable {
    var appType, channel, devicePlatform, deviceType: String?
}

// MARK: - UuID
struct UuID: Codable {
    var updatedStamp: Int?
    var value: String?
    var version: Int?
}


public protocol CherryTopicListener {
    func onTopicReceived(topic : String)
}
