//
//  ViewController.swift
//  smartconfigdemo
//
//  Created by Aruna on 13/7/20.
//  Copyright © 2020 Aruna. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.startSmartConfig()
    }
    
    func startSmartConfig() {
        let wm = WiFiManager();
        
        // Get the connected WiFi
        let ssid = wm.getSSID() ?? "";
        let bssid = wm.getBSSID() ?? "";
        let pass = "wifipassword"
         
        print("startSmartConfig # Smartconfig with ssid:\(ssid) bssid: \(bssid) pass: \(pass)");

         let instance = EspTouchManager.shareInstance
         var count = 0
         let onOnce: EspTouchManager.OnConfiguredOnceHandler = { [weak self] result in
             count += 1
             let ipString = "IP: " + ESP_NetUtil.descriptionInetAddr4(by: result.ipAddrData)
             print(ipString)
         }
         
         let onSuccess: EspTouchManager.OnSuccessHandler = { configResults  in
             print("startSmartConfig # esptouch configrue compelete, results: \(configResults)")
             var devices = [[String: String]]()

             for result in configResults {
                 if result.isSuc {
                     let dataToAppend: [String: String] = ["bssid": result.bssid!,
                                                           "ip" : result.getAddressString()!]
                     devices.append(dataToAppend)
                 }
             }
              
             let jsonObject: NSMutableDictionary = NSMutableDictionary()
             jsonObject.setValue(devices, forKey: "devices")
             let jsonData: NSData

             do {
                 jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions()) as NSData
                 let jsonString = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
                 print("startSmartConfig # json string = \(jsonString)")
                  
             } catch _ {
                 print ("startSmartConfig # JSON Failure")
             }

         }
         
         let onTimeout: EspTouchManager.OnCofiguredTimeout = {
             print("startSmartConfig # esptouch configrue timeout")
         }
         
         let onCanceled: EspTouchManager.OnCofigureCanceled = {
             print("startSmartConfig # esptouch has cancelled!")
         }
         
         _ = instance.configrue(ssid: ssid, bssid: bssid, passwd: pass,
                                         onOnce: onOnce,
                                         onSuccess: onSuccess,
                                         onTimeout: onTimeout,
                                         onCanceled: onCanceled)
        print("startSmartConfig # started!")
    }
    
    @IBAction func smartconfigClicked(_ sender: Any) {
        
    }
    
     
    
}

