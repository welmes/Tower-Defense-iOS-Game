//
//  Inventory.swift
//  Tower Defense Game
//
//  Created by William Elmes on 3/14/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

let invCols = 2
let invRows = 13

class InventoryFrame: SKNode {
    let basePos = CGPointMake(cellWidth * (numCols - 1.5), cellHeight * (numRows - 3.5))
    var slots = [[InventorySlotNode]]()
    
    override init() {
        super.init()
        
        for var row = 0; row < invRows; row++ {
            var invRow = [InventorySlotNode]()
            for var col = 0; col < invCols; col++ {
                let slot = InventorySlotNode(slotTexture: "InventorySlotFace", slotActiveTexture: "InventorySlotFaceActive", selectedTexture: "HighlightDotted")
                slot.position = CGPointMake(basePos.x + CGFloat(col) * cellWidth, basePos.y - CGFloat(row) * cellHeight)
                addChild(slot)
                invRow.append(slot)
            }
            slots.append(invRow)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func GetOpenSlot() -> (InventorySlotNode)? {
        for var row = 0; row < invRows; row++ {
            for var col = 0; col < invCols; col++ {
                if slots[row][col].gem == nil {
                    //print("Open slot found at (\(col), \(row))")
                    return slots[row][col]
                }
            }
        }
        
        return nil
    }
    
    func CreateGem(color: GemColor, rank: GemRank) {
        let slot = GetOpenSlot()
        
        if slot == nil {
            // TO DO: Print inventory full error message?
            print("No open inventory slot found")
            return
        }
        
        let gem = GemItem(gemColor: color, gemRank: rank)
        gem.itemSprite!.zPosition = 110
        slot!.gem = gem
        slot!.addChild(gem)
        //print("Gem created: \(gem.color!.rawValue), \(gem.rank!.rawValue) at (\(slots[slot!.r][slot!.c].position.x), \(slots[slot!.r][slot!.c].position.y))")
    }
    
    func SetPressedAction(action: ((InventorySlotNode) -> Void)) {
        for var row = 0; row < invRows; row++ {
            for var col = 0; col < invCols; col++ {
                slots[row][col].pressedAction = action
            }
        }
    }
}

class InventorySlotNode: SKNode {
    var gem: GemItem?
    
    var faceIdleTexture: String
    var faceActiveTexture: String
    let faceSprite: SKSpriteNode
    let selectedSprite: SKSpriteNode
    
    var pressedAction: ((InventorySlotNode) -> Void)?
    
    init(slotTexture: String, slotActiveTexture: String, selectedTexture: String) {
        faceIdleTexture = slotTexture
        faceActiveTexture = slotActiveTexture
        faceSprite = SKSpriteNode(imageNamed: faceIdleTexture)
        selectedSprite = SKSpriteNode(imageNamed: selectedTexture)
        super.init()
        
        addChild(faceSprite)
        addChild(selectedSprite)
        selectedSprite.hidden = true
        selectedSprite.zPosition = 200
        userInteractionEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        Depress()
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            
            if(faceSprite.containsPoint(location)) {
                Depress()
            }
            else {
                Release()
            }
        }
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        for touch in touches {
            let location = touch.locationInNode(self)
            
            if(faceSprite.containsPoint(location)) {
                Press()
                Release()
            }
        }
    }
    
    // Depress the slot, highlighting it
    func Depress() {
        faceSprite.texture = SKTexture(imageNamed: faceActiveTexture)
    }
    
    // Release the slot, removing highlight
    func Release() {
        faceSprite.texture = SKTexture(imageNamed: faceIdleTexture)
    }
    
    // Trigger the slot's pressed action
    func Press() {
        pressedAction?(self)
    }
}