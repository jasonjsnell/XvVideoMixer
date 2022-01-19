//
//  Channels.swift
//  XvVideoMixer
//
//  Created by Jason Snell on 11/24/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation

class Channels:UIViewController {
    
    fileprivate let debug:Bool = true
    
    
    //MARK: Vars
    fileprivate var _channels:[Channel] = []
    
    internal var total:Int {
        get { return _channels.count }
    }
    
    //MARK: Init
    internal init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
 
    //MARK: Add
    internal func addChannel(withVideoClipFileNames:[String], withRestingtAlpha:CGFloat){
        
        //create channel
        let _channel:Channel = Channel()
        
        //pass along clips
        _channel.addVideoClips(withFileNames: withVideoClipFileNames)
        
        //set target alpha (for channel pulses)
        _channel.set(restingAlpha: withRestingtAlpha)
        
        //add to view
        view.addSubview(_channel.view)
        
        //store in array for access
        _channels.append(_channel)
        
    }
    
    //MARK: Multiply render mode
    internal func set(multiply:Bool, forChannel:Int) {
        
        if (forChannel < _channels.count) {
            
            _channels[forChannel].set(multiply: multiply)
        }
    }
    
    //MARK: Alpha
    internal var alpha:CGFloat {
        get { return view.alpha }
        set {
            
            var newAlpha:CGFloat = newValue
            if (newAlpha < 0.0){
                newAlpha = 0.0
            } else if (newAlpha > 1.0){
                newAlpha = 1.0
            }
            view.alpha = newValue
            
        }
    }
    
    internal func set(alpha:CGFloat, forChannel:Int){
     
        if (forChannel < _channels.count) {
            
            _channels[forChannel].set(alpha: alpha)
        }
    }
    
    //MARK: channel pulses
    internal func set(restingAlpha:CGFloat, forChannel:Int){
        
        if (forChannel < _channels.count) {
            
            _channels[forChannel].set(restingAlpha: alpha)
        }
    
    }
    
    internal func pulse(channel:Int){
        
        if (channel < _channels.count) {
            
            _channels[channel].pulse()
            
        }
        
    }
    
    //MARK: LFO
    internal func set(lfoAlphaInc:CGFloat, forChannel:Int) {
        
        if (forChannel < _channels.count) {
            _channels[forChannel].set(lfoAlphaInc: lfoAlphaInc)
        }
    }
    
    internal func cancelLFO(forChannel:Int){
        
        if (forChannel < _channels.count) {
            _channels[forChannel].cancelLFO()
        }
    }
    
    //MARK: Speed
    //all channels
    internal func set(speed:Double){
        for _channel in _channels {
            _channel.set(speed: speed)
        }
    }
    
    //MARK: Render
    internal func render(){
        
        for _channel in _channels {
            _channel.render()
        }
    }
}
