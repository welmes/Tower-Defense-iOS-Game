//
//  ButtonNode.swift
//  Tower Defense Game
//
//  Created by William Elmes on 2/28/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

class ButtonNode: SKNode {
    var btnIdleTexture: SKTexture?
    var btnDepressedTexture: SKTexture?
    var btnDisabledTexture: SKTexture?
    
    var btnIdleTextureAlt: SKTexture?
    var btnDepressedTextureAlt: SKTexture?
    var btnDisabledTextureAlt: SKTexture?
    
    var isDisabled = false
    var hasAltButtonState = false
    //var hasAltIconState = false
    var currState = 0
    
    var btnSprite: SKSpriteNode
    //var iconSprite: SKSpriteNode?
    //var btnDepressedSprite: SKSpriteNode
    var pressedAction: (() -> Void)?
    var pressedActionAlt: (() -> Void)?
    
    // Default Constructor:
    //  - Single idle, depressed, and disabled texture
    //  - Icon is part of button texture
    init(buttonTexture: String, buttonDepressedTexture: String, buttonDisabledTexture: String) {
        btnIdleTexture = SKTexture(imageNamed: buttonTexture)
        btnDepressedTexture = SKTexture(imageNamed: buttonDepressedTexture)
        btnDisabledTexture = SKTexture(imageNamed: buttonDisabledTexture)
        
        btnSprite = SKSpriteNode(texture: btnIdleTexture)
        //btnDepressedSprite = SKSpriteNode(imageNamed: buttonDepressedTexture)
        //btnDepressedSprite.hidden = true
        
        super.init()
        userInteractionEnabled = true
        addChild(btnSprite)
        //addChild(btnDepressedSprite)
    }
    
    // Two-State Constructor:
    //  - Press action toggles between two states
    //  - Icon is part of button texture
    convenience init(buttonTexture: String, buttonDepressedTexture: String, buttonDisabledTexture: String, buttonTextureAlt: String, buttonDepressedTextureAlt: String, buttonDisabledTextureAlt: String) {
        self.init(buttonTexture: buttonTexture, buttonDepressedTexture: buttonDepressedTexture, buttonDisabledTexture: buttonDisabledTexture)
        
        hasAltButtonState = true
        btnIdleTextureAlt = SKTexture(imageNamed: buttonTextureAlt)
        btnDepressedTextureAlt = SKTexture(imageNamed: buttonDepressedTextureAlt)
        btnDisabledTextureAlt = SKTexture(imageNamed: buttonDisabledTextureAlt)
    }
    
//    // Separate Icon Constructor:
//    //  - Single idle and depressed texture
//    //  - Icon and button face are separate textures
//    convenience init(buttonTexture: String, buttonDepressedTexture: String, buttonIconTexture: String) {
//        self.init(buttonTexture: buttonTexture, buttonDepressedTexture: buttonDepressedTexture)
//        
//        iconTexture = buttonIconTexture
//        iconSprite = SKSpriteNode(imageNamed: iconTexture!)
//        iconSprite?.zPosition = 10
//        addChild(iconSprite!)
//    }
    
//    // Two-State Separate Icon Constructor:
//    //  - Press action toggles between two states
//    //  - Icon and button face are separate textures
//    convenience init(buttonTexture: String, buttonDepressedTexture: String, buttonIconTexture: String, buttonIconAltTexture: String) {
//        self.init(buttonTexture: buttonTexture, buttonDepressedTexture: buttonDepressedTexture)
//        
//        hasAltIconState = true
//        iconTexture = buttonIconTexture
//        iconAltTexture = buttonIconAltTexture
//        iconSprite = SKSpriteNode(imageNamed: iconTexture!)
//        iconSprite?.zPosition = 10
//        addChild(iconSprite!)
//    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        Depress()
        //btnDepressedSprite.hidden = false
        //btnIdleSprite.hidden = true
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            
            if(btnSprite.containsPoint(location)) {
                Depress()
                //btnDepressedSprite.hidden = false
                //btnIdleSprite.hidden = true
            }
            else {
                Release()
                //btnIdleSprite.hidden = false
                //btnDepressedSprite.hidden = true
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            
            if(btnSprite.containsPoint(location)) {
                Press()
                ToggleState()
                Release()
                //btnIdleSprite.hidden = false
                //btnDepressedSprite.hidden = true
            }
        }
    }
    
    // Depress the button, highlighting it
    func Depress() {
        if currState == 0 {
            btnSprite.texture = btnDepressedTexture
        }
        else {
            btnSprite.texture = btnDepressedTextureAlt
        }
    }
    
    // Release the button, removing highlight
    func Release() {
        if currState == 0 {
            btnSprite.texture = btnIdleTexture
        }
        else {
            btnSprite.texture = btnIdleTextureAlt
        }
    }
    
    // Trigger the button's pressed action
    func Press() {
        if currState == 0 {
            pressedAction?()
        }
        else {
            pressedActionAlt?()
        }
    }
    
    // Toggle the button's state if it has two states
    func ToggleState() {
        if hasAltButtonState {
            if currState == 0 {
//                if hasAltIconState {
//                    iconSprite!.texture = SKTexture(imageNamed: iconTextureAlt!)
//                }
                currState = 1
            }
            else {
//                if hasAltIconState {
//                    iconSprite!.texture = SKTexture(imageNamed: iconTexture!)
//                }
                currState = 0
            }
        }
    }
    
    // Changes the face textures of the button
    //  - Only do this while the button is disabled/hidden (NOT pressable)
    func ChangeTextures(buttonTexture: String, buttonDepressedTexture: String, buttonDisabledTexture: String) {
        btnIdleTexture = SKTexture(imageNamed: buttonTexture)
        btnDepressedTexture = SKTexture(imageNamed: buttonDepressedTexture)
        btnDisabledTexture = SKTexture(imageNamed: buttonDisabledTexture)
        Release()
    }
}