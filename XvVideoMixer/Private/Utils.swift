//
//  Utils.swift
//  XvVideoMixer
//
//  Created by Jason Snell on 11/24/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation

class Utils {
    
    class func postNotification(name:String, userInfo:[AnyHashable : Any]?){
        
        let notification:Notification.Name = Notification.Name(rawValue: name)
        NotificationCenter.default.post(
            name: notification,
            object: nil,
            userInfo: userInfo)
    }
    
    class func getBundlePath(fromFileName:String) -> String? {
        
        let stringComponents:[String] = fromFileName.components(separatedBy: ".")
        
        if (stringComponents.count < 2) {
            print("UTILS: fileName does not have a file extension during getBundleName fromFilePath")
            return nil
        }
        
        if let bundlePath:String = Bundle.main.path(forResource: stringComponents[0], ofType: stringComponents[1]) {
            
            return bundlePath
            
        } else {
            print("UTILS: Bundle path not found for", fromFileName)
            return nil
        }
        
    }
    
    class func getRandomInt(within: Int) -> Int {
        return Int(arc4random_uniform(UInt32(within)))
    }
    
    public class func getRandomFloat(betweenMin: Float, andMax: Float) -> Float {
        return getRandomFloat() * (andMax - betweenMin) + betweenMin
    }
    
    public class func getRandomFloat() -> Float {
        return Float.random(in: 0 ..< 1)
    }

}
