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
    
    
    fileprivate var _layers:[AVPlayerLayer] = []
    fileprivate var _selectedLayer:Int = 0
    fileprivate var _currTime:Int64 = 0
    fileprivate var _currSpeed:Int64 = 25
    
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
                
                let _videoLayer:AVPlayerLayer = _addVideoLayer(withBundlePath: bundlePath)
                _layers.append(_videoLayer)
                
            } else {
                print("VIDEO: Error getting bundle name from", fileName)
            }
        }
        
        _queueClip()
    }
    
    //MARK: Render

    internal func render(){
        
        _currTime += _currSpeed
        
        let newCMTime:CMTime = CMTimeMake(_currTime, SCALE)
        
        if let item:AVPlayerItem = _layers[_selectedLayer].player?.currentItem {
            
            if (newCMTime < item.asset.duration){
                
                if (debug){
                    print("CHANNEL: Clip", _selectedLayer, ",", newCMTime.value, "/", item.asset.duration.value)
                }
                
                _layers[_selectedLayer].player!.seek(
                    to: newCMTime,
                    toleranceBefore: kCMTimeZero,
                    toleranceAfter: kCMTimeZero
                )
                
            } else {
                
                _queueClip()
            }
        
        } else {
            print("CHANNEL: unable to get video player layer", _selectedLayer)
        }
    }
    
    //MARK: Alpha
    
    internal func set(alpha:CGFloat) {
        
        if (alpha >= 0.0 && alpha <= 1.0){
            self.view.alpha = alpha
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
    
    internal func set(speed:Float){
        
        //speed is coming in as a 0.0-1.0 float. Double it so midway (0.5) is normal speed, below is slower, above is faster
        let multiplier:Float = speed * 2
       
        let speedAsFloat:Float = Float(SPEED_BASE) * multiplier
        
        //apply
        _currSpeed = Int64(speedAsFloat)
        
        //makes sure speed is at least 1
        if (_currSpeed < 1) {
            _currSpeed = 1
        }
        
    }
    
    //MARK: Private helpers
    
    fileprivate func _queueClip(){
        
        //reset time
        _currTime = 0
        
        
        //generate new random clip if layers has more than one clip
        if (_layers.count > 1) {
            
            var _newLayer:Int = _selectedLayer
           
            repeat {
                
                _newLayer = Utils.getRandomInt(within: _layers.count)
                
            } while (_newLayer == _selectedLayer)
            
            _selectedLayer = _newLayer
           
            if (debug){
                print("CHANNEL: New clip", _selectedLayer, _layers[_selectedLayer].player?.currentItem?.asset as Any)
            }
            
        } else {
            
            _selectedLayer = 0
        }
        
        //remove curr sub layers
        if let _sublayers:[CALayer] = self.view.layer.sublayers {
            for layer in _sublayers {
                layer.removeFromSuperlayer()
            }
        }
        
        //add new sub layer
        self.view.layer.addSublayer(_layers[_selectedLayer])
    
    }
    
    fileprivate func _addVideoLayer(withBundlePath:String) -> AVPlayerLayer {
        
        let _player:AVPlayer = AVPlayer(url: URL(fileURLWithPath: withBundlePath))
        let _layer = AVPlayerLayer(player: _player)
        _layer.frame = self.view.bounds
        _layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return _layer
        
    }
    
}
