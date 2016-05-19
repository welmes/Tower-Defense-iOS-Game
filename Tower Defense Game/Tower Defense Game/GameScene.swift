//
//  GameScene.swift
//  Tower Defense Game
//
//  Created by William Elmes on 2/28/16.
//  Copyright (c) 2016 William Elmes. All rights reserved.
//

import SpriteKit

let numCols: CGFloat = 21 + 1/3
let numRows: CGFloat = 16
var cellWidth: CGFloat = 0
var cellHeight: CGFloat = 0

let textFont = "Courier"

var game: GameEngine?

class GameScene: SKScene {
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        cellWidth = self.frame.width / numCols
        cellHeight = self.frame.height / numRows
        
        game = GameEngine()
        game!.InitUi()
        game!.LoadLevel("Level1") // TO DO: Shut down if returns false
        addChild(game!)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        /* Called when a touch begins */
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}