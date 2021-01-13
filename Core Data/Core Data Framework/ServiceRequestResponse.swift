//
//  ServiceRequestResponse.swift
//  Core data framework
//

import UIKit
import SystemConfiguration
import CoreLocation

// API request/response
class ServiceRequestResponse: NSObject {
    
    static let sharedInstance = ServiceRequestResponse()
    static var inProgress = false //to avoid multiple hits
    static var apiUrl = String() //to avoid blocking and allow to call two different API at a time
    
    //API request and response
    func requestService(_ url:String, data: [String: AnyObject], completion: @escaping (_ response: [String: AnyObject]?,_ error: Error?) -> ()) {
        
        //set request and response time out
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 25.0
        sessionConfig.timeoutIntervalForResource = 40.0
        let defaultSession = URLSession(configuration: sessionConfig)
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        if (ServiceRequestResponse.inProgress == false) || (ServiceRequestResponse.inProgress == true && ServiceRequestResponse.apiUrl != url){
            ServiceRequestResponse.inProgress = true
            ServiceRequestResponse.apiUrl = url
            
            //POST parameter
            var request = URLRequest(url: URL(string: url)!)
            request.timeoutInterval = 25
            request.httpMethod = "POST"
            
            if let accessToken = UserDefaults.standard.string(forKey: "accessToken")
            {
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField:"Authorization")
            }
            
            do
            {
                //request
                let jsonData = try JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.prettyPrinted)
                request.httpBody = jsonData
                
            } catch {
                ServiceRequestResponse.inProgress = false
                ServiceRequestResponse.apiUrl = ""
                print("Json parser error: \(error)")
            }
            
            let task = defaultSession.dataTask(with: request, completionHandler: { data, response, error in
                if let httpResponse = response as? HTTPURLResponse {
                    print("Status Code: \(httpResponse.statusCode)")
                }
                
                ServiceRequestResponse.inProgress = false
                ServiceRequestResponse.apiUrl = ""
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                
                guard (error == nil) else {
                    
                    //error
                    completion(nil, error)
                    return }
                
                do {
                    
                    //response
                    guard let data = data, let responseData = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions(rawValue:0)) as? [String: AnyObject] else { completion(nil, error)
                        return }
                    
                    completion(responseData, error)
                } catch let error as NSError {
                    
                    //error
                    completion(nil, error)
                    print("Error parsing results: \(error.localizedDescription)")
                }
            })
            
            task.resume()
        }
    }
}

// Internet Connection
open class Reachability {
    
    class func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        
        return (isReachable && !needsConnection)
    }
}
