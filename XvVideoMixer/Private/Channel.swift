//
//  Channel.swift
//  XvVideoMixer
//
//  Created by Jason Snell on 11/24/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import UIKit
import AVFoundation

class Channel:UIViewController {
    
    //MARK: Vars
    fileprivate let SCALE:Int32 = 600 //same as normal player
    fileprivate let SPEED_BASE:Int64 = 25
    
    fileprivate let PULSE_ALPHA_DECREASE_INC:CGFloat = 0.01
    
    fileprivate var _bundlePaths:[String] = []
    fileprivate var _avPlayerLayer:AVPlayerLayer?
    
    fileprivate var _selectedClip:Int = 0
    fileprivate var _currTime:Int64 = 0
    fileprivate var _currSpeed:Int64 = 25
    
    //this is the alpha set by the incoming knob data
    //alpha cannot go above this
    fileprivate var _targetAlpha:CGFloat = 1.0
    
    //when a pulse is complete, this is the alpha the channel drifts down to
    fileprivate var _restingAlpha:CGFloat = 1.0
    
    //render mode
    fileprivate var _multiply:Bool = false
    
    fileprivate let debug:Bool = false
    
    //MARK: Init
    internal init(){
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //init here?
    }
    
    //MARK: Add
    internal func addVideoClips(withFileNames:[String]) {
        
        for fileName in withFileNames {
            
            if let bundlePath:String = Utils.getBundlePath(fromFileName: fileName) {
                
                _bundlePaths.append(bundlePath)
                
            } else {
                print("VIDEO: Error getting bundle name from", fileName)
            }
        }
        
        _newClip(atTime: 0)
    }
    
    //MARK: Render
    
    internal func set(multiply:Bool) {
        _multiply = multiply
    }

    internal func render(){
        
        if (_multiply){
            self.view.layer.compositingFilter = "multiplyBlendMode"
        }
        
        _currTime += _currSpeed
        
        let newCMTime:CMTime = CMTimeMake(value: _currTime, timescale: SCALE)
        
        if (_avPlayerLayer != nil) {
            
            if let item:AVPlayerItem = _avPlayerLayer!.player?.currentItem {
                
                if (newCMTime < item.asset.duration){
                    
                    if (debug){
                        print("CHANNEL: Clip", _selectedClip, ",", newCMTime.value, "/", item.asset.duration.value)
                    }
                    
                    _avPlayerLayer!.player!.seek(
                        to: newCMTime,
                        toleranceBefore: CMTime.zero,
                        toleranceAfter: CMTime.zero
                    )
                    
                } else {
                    
                    _newClip(atTime: 0)
                }
                
            } else {
                print("CHANNEL: unable to get video player layer", _selectedClip)
            }
            
        } else {
            print("CHANNEL: _avPlayerLayer is nil during render")
        }
        
        //channel pulse
        if (self.view.alpha > _restingAlpha){
            
            let newAlpha:CGFloat = self.view.alpha - PULSE_ALPHA_DECREASE_INC
            if (newAlpha >= 0.0){
                self.view.alpha = newAlpha
            }
            
            
        }
        
    }
    
    //MARK: Pulse
    
    internal func pulse(){
        
        let randomInt:Int = Utils.getRandomInt(within: 1000)
        let randomInt64:Int64 = Int64(randomInt)
        _newClip(atTime: randomInt64)
        set(alpha: 1.0 * _targetAlpha)
        
    }
    
    //MARK: Alpha
    
    internal func set(alpha:CGFloat) {
        
        if (alpha >= 0.0 && alpha <= 1.0){
            _targetAlpha = alpha
            self.view.alpha = alpha
            
            if (debug){
                print("CHANNEL: Set alpha to", alpha)
            }
        }
        
    }
    
    //channel pulse
    internal func set(restingAlpha:CGFloat){
        
        if (restingAlpha >= 0.0 && restingAlpha <= 1.0){
            _restingAlpha = restingAlpha
        }
        
    }
    
    //MARK:LFO
    fileprivate var _lfoTimer:Timer = Timer()
    fileprivate let LFO_LOOP:TimeInterval = 0.1
    fileprivate var _lfoActive:Bool = false
    fileprivate var _lfoDirection:Int = 0
    fileprivate var _lfoAlphaInc:CGFloat = 0.1
    
    internal func set(lfoAlphaInc:CGFloat) {
        
        _lfoAlphaInc = lfoAlphaInc
        _lfoActive = true
        
        //LFO_LOOP
        
        _lfoTimer.invalidate()
        _lfoTimer = Timer.scheduledTimer(
            timeInterval: LFO_LOOP,
            target: self,
            selector: #selector(lfoFire),
            userInfo: nil,
            repeats: true
        )
        
    }
    
    @objc internal func lfoFire(){
        
        var newAlpha:CGFloat = 0.0
        
        if (_lfoDirection == 0){
            
            //down, calc new alpha
            newAlpha = self.view.alpha - _lfoAlphaInc
            
            //if zero or less
            if (newAlpha <= 0) {
                
                //set to zero
                newAlpha = 0
                
                //reverse direction
                _lfoDirection = 1
            }
            
        
        } else {
            
            //up, calc new alpha
            newAlpha = self.view.alpha + _lfoAlphaInc
            
            //if zero or less
            if (newAlpha >= 1.0) {
                
                //set to zero
                newAlpha = 1.0
                
                //reverse direction
                _lfoDirection = 0
            }
            
        }
        
        set(alpha: newAlpha)
        
    }
    
    internal func cancelLFO(){
        _lfoActive = false
        _lfoTimer.invalidate()
    }
    
    //MARK: Speed
    
    internal func set(speed:Double){
        
        if (debug){
            print("CHANNEL: Set speed to", speed)
        }
        
        
        //speed is coming in as a 0.0-1.0 float. Double it so midway (0.5) is normal speed, below is slower, above is faster
        let multiplier:Double = speed * 2
       
        let speedAsDouble:Double = Double(SPEED_BASE) * multiplier
        
        //apply
        _currSpeed = Int64(speedAsDouble)
        
        //makes sure speed is at least 1
        if (_currSpeed < 1) {
            _currSpeed = 1
        }
        
    }
    
    //MARK: Private helpers
    
    fileprivate func _newClip(atTime:Int64){
        
        _currTime = atTime
        
        _newClip()
    }
    
    fileprivate func _newClip(){
        
        
        //generate new random clip if layers has more than one clip
        if (_bundlePaths.count > 1) {
            
            var _newClip:Int = _selectedClip
           
            //make sure it doesn't select same clip as last time
            repeat {
                
                _newClip = Utils.getRandomInt(within: _bundlePaths.count)
                
            } while (_newClip == _selectedClip)
            
            _selectedClip = _newClip
            
        } else {
            
            _selectedClip = 0
        }
        
        //remove curr sub layers
        if let _sublayers:[CALayer] = self.view.layer.sublayers {
            for layer in _sublayers {
                layer.removeFromSuperlayer()
            }
        }
        
        //clear previous player
        _avPlayerLayer = nil
        
        //create new av player layer with selected clip
        _avPlayerLayer = _getAvPlayerLayer(fromBundlePath: _bundlePaths[_selectedClip])
        
        //add as sub layer
        self.view.layer.addSublayer(_avPlayerLayer!)
        
        if (debug){
            print("CHANNEL: New clip", _avPlayerLayer!.player?.currentItem?.asset as Any)
        }
    
    }
    
    fileprivate func _getAvPlayerLayer(fromBundlePath:String) -> AVPlayerLayer {
        
        let _player:AVPlayer = AVPlayer(url: URL(fileURLWithPath: fromBundlePath))
        let _layer = AVPlayerLayer(player: _player)
        _layer.frame = self.view.bounds
        _layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return _layer
        
    }
    
}
