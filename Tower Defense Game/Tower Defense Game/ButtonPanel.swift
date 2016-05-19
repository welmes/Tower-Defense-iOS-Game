//
//  ButtonPanel.swift
//  Tower Defense Game
//
//  Created by William Elmes on 4/13/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

class ButtonPanel: SKNode {
    var btns = [ButtonNode]()
    
    func Add(btn: ButtonNode) {
        btns.append(btn)
        addChild(btn)
    }
    
    func Btn(i: Int) -> ButtonNode? {
        if i < 0 || i >= btns.count {
            return nil
        }
        
        return btns[i]
    }
    
    func Hide() {
        for btn in btns {
            btn.hidden = true
            btn.userInteractionEnabled = false
        }
    }
    
    func Show() {
        for btn in btns {
            btn.hidden = false
            btn.userInteractionEnabled = true
        }
    }
}