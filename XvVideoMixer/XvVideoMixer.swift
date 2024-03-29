//
//  XvVideoMixer.swift
//  XvVideoMixer
//
//  Created by Jason Snell on 11/24/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation


public class XvVideoMixer {
    
    //MARK: Vars
    
    fileprivate let debug:Bool = true
    
    fileprivate var _autoPilotTimer:Timer = Timer()
    fileprivate var _autoPilotEnabled:Bool = true
    public var autoPilotEnabled:Bool {
        get { return _autoPilotEnabled }
        set { _autoPilotEnabled = newValue }
    }
    
    fileprivate var _timeSinceContact:Int = 0
    
    fileprivate let FPS_24:TimeInterval = 0.041667
    fileprivate let FADE_OUT_INC:CGFloat = 0.25
    
    fileprivate let _channels:Channels = Channels()
    
    fileprivate let _masks:Masks = Masks()
    fileprivate var _maskAlpha:CGFloat = 1.0
    
    fileprivate let _videoMixer:UIViewController = UIViewController()
    fileprivate var _masterAlpha:CGFloat = 1.0
    
    //CLOCK
    fileprivate let CLOCK_MAX:Int = 768 // 8 patterns
    fileprivate var _clockCount:Int = 0
    fileprivate var _clockDivider:Int = 0
    
    fileprivate var _clockPhaseShiftForDivider:Int = 0
    public var clockDivider:Int {
        get { return _clockDivider }
        set {
            _clockDivider = newValue
            print("VIDEO: Clock divider is now", _clockDivider)
            
            //reset clock when divider is reset
            //allow user to manually sync the beat when hitting a midi trigger
            
            if (_clockDivider != 0){
                _clockCount = 0
                pulse()
            }
            
            
        }
    }
    
    //length of time of pulse anim
    //short times are just a brief burst of image
    fileprivate var _release:Double = 0.0
    public var release:Double {
        get { return _release }
        set { _release = newValue }
    }
    

    
    
    //access to the channels view, which contains all indivudal channels and clips
    public var videoMixerView:UIView {
        get { return _videoMixer.view }
    }
    
    public func set(scale:CGFloat){
        _videoMixer.view.transform = CGAffineTransform(scaleX: scale, y: scale);
    }
    
    
    
    //MARK: Init
    //singleton code
    public static let sharedInstance = XvVideoMixer()
   
    fileprivate init(){
        
        _videoMixer.view.addSubview(_channels.view)
        _videoMixer.view.addSubview(_masks.view)
        
    }
    
    //MARK: Add
    //init channel with full alpha
    public func addChannel(withVideoClipFileNames:[String]){
        
        addChannel(withVideoClipFileNames: withVideoClipFileNames, withRestingtAlpha: 1.0)
    }
    
    //init channel with target alpha
    public func addChannel(withVideoClipFileNames:[String], withRestingtAlpha:CGFloat){
        
        _channels.addChannel(withVideoClipFileNames: withVideoClipFileNames, withRestingtAlpha: withRestingtAlpha)
    }
    
    public func addMask(withImageName:String) {
        
        _masks.addMask(withImageName: withImageName)
    }
    
    public func addMask(withImageName:String, withAlpha: CGFloat) {
        
        _masks.addMask(withImageName: withImageName, withAlpha: withAlpha)
    }
    
    //MARK: Playback
    
    fileprivate var playbackTimer:Timer?
    
    public func play(){
        
        //clear timer
        stop()
        
        //re-init timer
        playbackTimer = Timer.scheduledTimer(
            timeInterval: FPS_24,
            target: self,
            selector: #selector(render),
            userInfo: nil,
            repeats: true
        )
    }
    
    public func stop(){
        
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    //MARK: Render
    @objc internal func render(){
        
        //render the channels
        _channels.render()
        
        if (_clockDivider > 0){
            
            //if clock is not zero, fade out the channels (the pulse brings them back up)
            
            let fadeOut:CGFloat =
                (FADE_OUT_INC / (CGFloat(_clockDivider) / 12.0)) *
                CGFloat(1.0 - release)
        
            _channels.alpha = _channels.alpha - fadeOut
            _masks.alpha = _masks.alpha - fadeOut
            
        } else {
            
            //clock is zero, no pulse
            
            if (_channels.alpha < _masterAlpha){
                
                //fade in non-pulsing channel from wherever the last pulse left it off until it is to master alpha
                _channels.alpha = _channels.alpha + 0.01
                _masks.alpha = _masks.alpha + 0.01
            }
        
        }
        
        //time since contact
        
        if (debug){
            if (_timeSinceContact > 0){
                //print("VIDEO: Time since contact:", _timeSinceContact)
            }
        }
        
        //up count
        _timeSinceContact += 1
        
        //launch autopilot if enabled
        if (_timeSinceContact == 25){
            
            if (_autoPilotEnabled) {
                
                _launchAutoPilot()
            }
            
        } else if (_timeSinceContact > 250){
            
            //else set clock back
            _timeSinceContact = 101
            
            //and make a search for bluetooth devices
            //print("XvVideoMixer scan request")
            Utils.postNotification(name: "kXvBluetoothScanRequest", userInfo: nil)
        }
        
        
        
        
    }
    
    //MARK: Pulse
    public func pulse(){
        
        //bring up alpha on all
        let newAlpha:CGFloat = 1.0 * _masterAlpha
        
        _channels.alpha = newAlpha
        _masks.alpha = newAlpha * _maskAlpha
    }
    
    public func pulse(channel:Int){
        
        //contact is being made, put var to zero
        _timeSinceContact = 0
        
        //force clock divider to be zero, so tempo pulse doesn't occur
        _clockDivider = 0
        
        //bring up the channels and the masks
        _channels.alpha = _masterAlpha
        _masks.alpha = _masterAlpha
        
        //set channel alpha
        _channels.pulse(channel: channel)

    }
    
    //MARK: MIDI clock
    
    public func midiClockTick(){
        
        //contact is being made, put var to zero
        _timeSinceContact = 0
        
        
        //advance clock count, used in pulse calc
        _clockCount += 1
        
        //if clock is not zero
        if (_clockDivider > 0){
           
            //get modulo, if zero, time to fire pulse
            if (_clockCount % _clockDivider == 0){
                
                pulse()
            }
        }
        
        //if clock gets to max, reset
        if (_clockCount >= CLOCK_MAX){
            
            //reset clock
            _clockCount = 0
        }
    }
    
    
    //MARK: Multiply render mode
    public func set(multiply:Bool, forChannel:Int) {
        
        _channels.set(multiply: multiply, forChannel: forChannel)
    }
    
    //MARK: Alpha
    public func set(alpha:CGFloat, forChannel:Int){
        
        _channels.set(alpha: alpha, forChannel: forChannel)
    }
    
    public func set(alpha:CGFloat, forMask:Int){
    
        _masks.set(alpha: alpha, forMask: forMask)
    }
    
    public var masterAlpha:CGFloat {
        get { return _masterAlpha }
        set {
            
            _masterAlpha = newValue
            
            if (debug){
                print("CHANNELS: Set master alpha to", newValue)
            }
            
        }
    }
    
    public var maskAlpha:CGFloat {
        get { return _maskAlpha}
        set { _maskAlpha = newValue }
    }
    
    
    //MARK: Speed
    
    public func set(speed:Double){
        _channels.set(speed: speed)
    }
    
    //MARK: AutoPilot
    
    
    
    fileprivate func _launchAutoPilot(){
        
        if (debug){ print("VIDEO: Start autopilot") }
        
        //hide all the masks except the top one
        for m in 0..<_masks.total {
            
            if (m < _masks.total-1){
                _masks.set(alpha: 0.0, forMask: m)
            } else {
                _masks.set(alpha: 1.0, forMask: m)
            }
        }
        
        //stop pulsing
        clockDivider = 0
        
        //add lfos to all the channels
        for c in 0..<_channels.total {
            
            let randomFloat:Float = Utils.getRandomFloat(betweenMin: 0.001, andMax: 0.025)
            let randomCGFloat:CGFloat = CGFloat(randomFloat)
            
            if (debug){ print("VIDEO: Set channel LFO inc to", randomCGFloat) }
            
            _channels.set(lfoAlphaInc: randomCGFloat, forChannel: c)
        }
        
        //set master to full
        masterAlpha = 1.0
        
    }
    
    public func cancelAutoPilot(){
        
        if (debug){ print("VIDEO: Cancel autopilot") }
        
        for c in 0..<_channels.total {
            
            _channels.cancelLFO(forChannel: c)
        }
        
    }
    
    
}
