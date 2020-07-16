//
//  EspTouchManager.swift
//  Runner
//
//  Created by Aruna on 13/7/20.
//

import Foundation
  
class EspTouchManager: NSObject {
    
    typealias OnSuccessHandler = ([ESPTouchResult]) -> Void
    
    typealias OnConfiguredOnceHandler = (ESPTouchResult) -> Void
    
    typealias OnCofiguredTimeout = () -> Void
    
    typealias OnCofigureCanceled = () -> Void
    
    var opQueue: DispatchQueue
    
    var touchTask: ESPTouchTask?
    
    var isConfiguring: Bool
    
    var condition: NSCondition
    
    var onConfiguredOnce: OnConfiguredOnceHandler?
    
    static var shareInstance = EspTouchManager()
    
    override init() {
        isConfiguring = false
        condition = NSCondition()
        opQueue = DispatchQueue(label: "pro.sinric.smartconfig.esptouchmanager")
    }
}

extension EspTouchManager {
    
    func cancel() {
        condition.lock()
        if let task = touchTask {
            task.interrupt()
            isConfiguring = false
        }
        condition.unlock()
    }
    
    func configrue(ssid: String, bssid: String, passwd: String, isHidden: Bool = false, count: Int32 = Int32.max,
                   onOnce: OnConfiguredOnceHandler?,
                   onSuccess: OnSuccessHandler?,
                   onTimeout: OnCofiguredTimeout?,
                   onCanceled: OnCofigureCanceled?) -> Bool {
        guard isConfiguring == false else {
            return false
        }
        
        isConfiguring = true
        onConfiguredOnce = onOnce
        
        opQueue.async {
            // execute the task
            let results = self.exectue(ssid: ssid, bssid: bssid, passwd: passwd, isHidden: isHidden, count: count)
            
            // show the result to the user in UI Main Thread
            DispatchQueue.main.async {
                self.isConfiguring = false
                if let fristResult = results.first {
                    // check whether the task is cancelled and no results received
                    if fristResult.isCancelled == false {
                        if fristResult.isSuc {
                            print("\(results)")
                            onSuccess?(results)
                        } else {
                            print("frist result is failed")
                            onTimeout?()
                        }
                    } else {
                        print("frist result is cancelled")
                        onCanceled?()
                    }
                } else {
                    print("frist result is nil")
                }
            }
        }
        
        return true
    }
}

extension EspTouchManager {
    fileprivate func exectue(ssid: String, bssid: String, passwd: String, isHidden: Bool, count: Int32) -> [ESPTouchResult] {
        condition.lock()
        
        touchTask = ESPTouchTask(apSsid: ssid, andApBssid: bssid, andApPwd: passwd, andIsSsidHiden: isHidden, andTimeoutMillisecond: 45*1000)
        touchTask!.setEsptouchDelegate(self)
        
        condition.unlock()
        
        return touchTask!.execute(forResults: count) as! [ESPTouchResult]
    }
}

// MARK: ESPTouchDelegate
extension EspTouchManager: ESPTouchDelegate {
    
    // on cofing
    func onEsptouchResultAdded(with result: ESPTouchResult!) {
        print("esptouch on result return: \(result)")
        DispatchQueue.main.async {
            self.onConfiguredOnce?(result)
        }
    }
}
