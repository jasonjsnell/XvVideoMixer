//
//  Masks.swift
//  XvVideoMixer
//
//  Created by Jason Snell on 11/25/17.
//  Copyright © 2017 Jason J. Snell. All rights reserved.
//

import Foundation

class Masks:UIViewController {
    
    //MARK: Vars
    fileprivate var _masks:[UIImageView] = []
    
    internal var total:Int {
        get { return _masks.count }
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
    
    public func addMask(withImageName:String) {
        
        addMask(withImageName: withImageName, withAlpha: 1.0)
    }
    
    public func addMask(withImageName:String, withAlpha: CGFloat) {
        
        if let image:UIImage = UIImage(named: withImageName){
            
            let imageView:UIImageView = UIImageView(image: image)
            
            if (image.size.width > image.size.height) {
                imageView.contentMode = UIViewContentMode.scaleAspectFit
                //since the width > height we may fit it and we'll have bands on top/bottom
            } else {
                imageView.contentMode = UIViewContentMode.scaleAspectFill
                //width < height we fill it until width is taken up and clipped on top/bottom
            }
            
            
            imageView.alpha = withAlpha
            imageView.frame = self.view.bounds
            self.view.addSubview(imageView)
            
            _masks.append(imageView)
            
            print("MASKS: Added")
            
        } else {
            
            print("MASKS: Image name", withImageName, "not valid when creating image")
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
    
    internal func set(alpha:CGFloat, forMask:Int) {
        
        if (forMask < _masks.count) {
            _masks[forMask].alpha = alpha
        }
        
    }
}

