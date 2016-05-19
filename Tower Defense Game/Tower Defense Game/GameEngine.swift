//
//  GameEngine.swift
//  Tower Defense Game
//
//  Created by William Elmes on 3/13/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

enum GameState: Int {
    case Default = 0
    case CreateTower
    case SelectGemRank
    case SelectGemColor
    case FuseGems
}

let timerTickDuration: Double = 0.5

class GameEngine: SKNode {
    let optionsBtn = ButtonNode(buttonTexture: "OptionsButton", buttonDepressedTexture: "OptionsButtonActive", buttonDisabledTexture: "OptionsButtonDisabled")
    let fastForwardBtn = ButtonNode(buttonTexture: "FastForwardButton", buttonDepressedTexture: "FastForwardButtonActive", buttonDisabledTexture: "FastForwardButtonDisabled")
    let pauseBtn = ButtonNode(buttonTexture: "PauseButton", buttonDepressedTexture: "PauseButtonActive", buttonDisabledTexture: "PauseButtonDisabled", buttonTextureAlt: "PlayButton", buttonDepressedTextureAlt: "PlayButtonActive", buttonDisabledTextureAlt: "PlayButtonDisabled")
    let toolsBtn = ButtonNode(buttonTexture: "UpgradeToolsButton", buttonDepressedTexture: "UpgradeToolsButtonActive", buttonDisabledTexture: "UpgradeToolsButtonDisabled")
    let createTowerBtn = ButtonNode(buttonTexture: "CreateTowerButton", buttonDepressedTexture: "CreateTowerButtonActive", buttonDisabledTexture: "CreateTowerButtonDisabled", buttonTextureAlt: "CancelCreateTowerButton", buttonDepressedTextureAlt: "CancelCreateTowerButtonActive", buttonDisabledTextureAlt: "CancelCreateTowerButtonDisabled")
    let createGemBtn = ButtonNode(buttonTexture: "CreateGemButton", buttonDepressedTexture: "CreateGemButtonActive", buttonDisabledTexture: "CreateGemButtonDisabled", buttonTextureAlt: "CancelCreateGemButton", buttonDepressedTextureAlt: "CancelCreateGemButtonActive", buttonDisabledTextureAlt: "CancelCreateGemButtonDisabled")
    let fuseGemsBtn = ButtonNode(buttonTexture: "FuseGemsButton", buttonDepressedTexture: "FuseGemsButtonActive", buttonDisabledTexture: "FuseGemsButtonDisabled", buttonTextureAlt: "CancelFuseGemsButton", buttonDepressedTextureAlt: "CancelFuseGemsButtonActive", buttonDisabledTextureAlt: "CancelFuseGemsButtonDisabled")
    
    var selectGemPanel = ButtonPanel()
    
    let timerIcon = SKSpriteNode(imageNamed: "TimerIcon")
    let waveIcon = SKSpriteNode(imageNamed: "WaveIcon")
    let scoreIcon = SKSpriteNode(imageNamed: "ScoreIcon")
    let energyIcon = SKSpriteNode(imageNamed: "EnergyIcon")
    let healthIcon = SKSpriteNode(imageNamed: "HealthIcon")
    
    let timerLabel = SKLabelNode(fontNamed: textFont)
    let waveLabel = SKLabelNode(fontNamed: textFont)
    let scoreLabel = SKLabelNode(fontNamed: textFont)
    let energyLabel = SKLabelNode(fontNamed: textFont)
    let healthLabel = SKLabelNode(fontNamed: textFont)
    
    let map = MapFrame()
    let inv = InventoryFrame()
    
    var gameState: GameState = .Default
    var selectedGemRank: GemRank?
    var selectedGemColor: GemColor?
    var selectedMapCell: MapCellNode?
    var selectedInventorySlot: InventorySlotNode?
    
    var rounds = [LevelRound]()
    
    var timerCounter: Double = 0
    var playerScore: Double = 0
    var playerHp: Int = 0
    var playerEnergy: Double = 0
    
    override init() {
        var currPos: CGPoint
        
        currPos = CGPointMake(cellWidth * (numCols - 0.5), cellHeight * (numRows - 0.5))
        optionsBtn.position = currPos
        
        currPos.x -= cellWidth * (3 + 1/3)
        energyIcon.position = currPos
        
        energyLabel.position = CGPointMake(currPos.x + cellWidth * 0.35, currPos.y)
        energyLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        energyLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        energyLabel.fontColor = SKColor.blackColor()
        energyLabel.fontSize = cellHeight * 0.5
        energyLabel.text = "000"
        
        currPos.x -= cellWidth * 2
        healthIcon.position = currPos
        
        healthLabel.position = CGPointMake(currPos.x + cellWidth * 0.45, currPos.y)
        healthLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        healthLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        healthLabel.fontColor = SKColor.blackColor()
        healthLabel.fontSize = cellHeight * 0.5
        healthLabel.text = "00"
        
        currPos = CGPointMake(cellWidth / 2, cellHeight * (numRows - 0.5))
        pauseBtn.position = currPos
        
        currPos.x += cellWidth
        fastForwardBtn.position = currPos
        
        currPos.x += cellWidth
        timerIcon.position = currPos
        
        timerLabel.position = CGPointMake(currPos.x + cellWidth * 0.35, currPos.y)
        timerLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        timerLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        timerLabel.fontColor = SKColor.blackColor()
        timerLabel.fontSize = cellHeight * 0.5
        timerLabel.text = "0:00"
        
        currPos.x += cellWidth * 2
        waveIcon.position = currPos
        
        waveLabel.position = CGPointMake(currPos.x + cellWidth * 0.4, currPos.y)
        waveLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        waveLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        waveLabel.fontColor = SKColor.blackColor()
        waveLabel.fontSize = cellHeight * 0.5
        waveLabel.text = "00/00"
        
        currPos.x += cellWidth * 3
        scoreIcon.position = currPos
        
        scoreLabel.position = CGPointMake(currPos.x + cellWidth * 0.45, currPos.y)
        scoreLabel.verticalAlignmentMode = SKLabelVerticalAlignmentMode.Center
        scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        scoreLabel.fontColor = SKColor.blackColor()
        scoreLabel.fontSize = cellHeight * 0.5
        scoreLabel.text = "000000"
        
        currPos = CGPointMake(cellWidth * (numCols - 1.5), cellHeight * (numRows - 1.5))
        toolsBtn.position = currPos
        
        currPos.x += cellWidth
        createTowerBtn.position = currPos
        
        currPos.x -= cellWidth
        currPos.y -= cellHeight
        createGemBtn.position = currPos
        
        currPos.x += cellWidth
        fuseGemsBtn.position = currPos
        
        currPos = CGPointMake(cellWidth * (numCols - 1.5), cellHeight * (numRows - 3.5))
        for var rank = 0; rank < GemRank.vals.count; rank++ {
            let btn = ButtonNode(buttonTexture: "GemWhite\(rank)Button", buttonDepressedTexture: "GemWhite\(rank)ButtonActive", buttonDisabledTexture: "GemWhite\(rank)ButtonDisabled")
            btn.position = CGPointMake(currPos.x, currPos.y - cellHeight * CGFloat(rank))
            btn.zPosition = 500
            selectGemPanel.Add(btn)
        }
        selectGemPanel.Hide()
        
//        var path = Array(count: mapHeight, repeatedValue: Array(count: mapWidth, repeatedValue: true))
//        path[0][1] = false
//        path[2][2] = false
//        path[2][3] = false
//        path[6][8] = false
//        path[5][8] = false
//        path[6][7] = false
//        path[6][8] = false
//        path[6][9] = false
//        path[6][10] = false
//        path[6][11] = false
//        path[6][12] = false
//        //path[6][13] = false
//        path[6][14] = false
//        path[6][15] = false
//        path[6][16] = false
//        path[8][17] = false
//        path[8][16] = false
//        path[8][15] = false
//        path[8][14] = false
//        path[7][8] = false
//        path[8][8] = false
//        map.Load(Tileset.Sand, pathMap: path)
//        map.SetPathing((x: 0, y: 1), endCoords: (x: mapWidth - 1, y: mapHeight - 1))
        
        //round = LevelRound(start: map.startCell!)
        
        super.init()
        
        addChild(optionsBtn)
        addChild(energyIcon)
        addChild(energyLabel)
        addChild(healthIcon)
        addChild(healthLabel)
        addChild(pauseBtn)
        addChild(fastForwardBtn)
        addChild(timerIcon)
        addChild(timerLabel)
        addChild(waveIcon)
        addChild(waveLabel)
        addChild(scoreIcon)
        addChild(scoreLabel)
        addChild(toolsBtn)
        addChild(createTowerBtn)
        addChild(createGemBtn)
        addChild(fuseGemsBtn)
        addChild(selectGemPanel)
        addChild(map)
        addChild(inv)
        //addChild(round)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func InitUi() {
        optionsBtn.pressedAction = PressOptionsBtn
        
        pauseBtn.pressedAction = PressPauseBtn
        pauseBtn.pressedActionAlt = PressPlayBtn
        
        fastForwardBtn.pressedAction = PressFastForwardBtn
        
        toolsBtn.pressedAction = PressToolsBtn
        
        createTowerBtn.pressedAction = PressCreateTowerBtn
        createTowerBtn.pressedActionAlt = PressCreateTowerBtn
        
        createGemBtn.pressedAction = PressCreateGemBtn
        createGemBtn.pressedActionAlt = PressCreateGemBtn
        
        selectGemPanel.Btn(0)?.pressedAction = PressSelectGem0Btn
        selectGemPanel.Btn(1)?.pressedAction = PressSelectGem1Btn
        selectGemPanel.Btn(2)?.pressedAction = PressSelectGem2Btn
        selectGemPanel.Btn(3)?.pressedAction = PressSelectGem3Btn
        selectGemPanel.Btn(4)?.pressedAction = PressSelectGem4Btn
        
        fuseGemsBtn.pressedAction = PressFuseGemsBtn
        fuseGemsBtn.pressedActionAlt = PressFuseGemsBtn
        
        map.SetPressedAction(PressMapCell)
        
        inv.SetPressedAction(PressInventorySlot)
    }
    
    func LoadLevel(fileName: String) -> Bool {
        if !ParseLevel(fileName) {
            return false
        }
        
        return true
    }
    
    func StartNextWave() {
        if rounds.first != nil {
            rounds.first!.StartNextWave()
            map.StartTowerTargetSearch()
        }
    }
    
    func PressOptionsBtn() {
        print("Options button pressed")
        ModifyPlayerHp(-1)
        ModifyPlayerEnergy(5)
    }
    
    func PressFastForwardBtn() {
        print("Fast forward button pressed")
        //activeRound = round
        StartNextWave()
        
        //let pos = convertPoint(map.startCell!.position, fromNode: map)
        //print("startCell(\(pos.x / cellWidth), \(pos.y / cellWidth))")
    }
    
    func PressPauseBtn() {
        print("Pause button pressed")
    }
    
    func PressPlayBtn() {
        print("Play button pressed")
    }
    
    func PressToolsBtn() {
        print("Tools button pressed")
    }
    
    func PressCreateTowerBtn() {
        if gameState != .CreateTower {
            print("Create tower button pressed")
            CancelState()
            gameState = .CreateTower
        }
        else {
            print("Create tower cancelled")
            gameState = .Default
        }
    }
    
    func PressCreateGemBtn() {
        if gameState != .SelectGemRank && gameState != .SelectGemColor {
            print("Create gem button pressed")
            CancelState()
            for var btn = 0; btn < selectGemPanel.btns.count; btn++ {
                selectGemPanel.Btn(btn)?.ChangeTextures("GemWhite\(btn)Button", buttonDepressedTexture: "GemWhite\(btn)ButtonActive", buttonDisabledTexture: "GemWhite\(btn)ButtonDisabled")
                //selectGemPanel.Btn(btn)?.iconSprite?.texture = SKTexture(imageNamed: selectGemPanel.Btn(btn)!.iconTexture!)
            }
            selectGemPanel.Show()
            gameState = .SelectGemRank
        }
        else {
            print("Create gem cancelled")
            selectGemPanel.Hide()
            gameState = .Default
        }
    }
    
    func PressFuseGemsBtn() {
        if gameState != .FuseGems {
            print("Fuse gem button pressed")
            CancelState()
            gameState = .FuseGems
        }
        else {
            print("Fuse gem cancelled")
            gameState = .Default
        }
    }
    
    func PressMapCell(cell: MapCellNode) {
        if gameState == .CreateTower {
            map.CreateTower(cell)
        }
        else {
            SelectMapCell(cell)
        }
    }
    
    func PressSelectGem0Btn() {
        PressSelectGemBtn(0)
    }
    
    func PressSelectGem1Btn() {
        PressSelectGemBtn(1)
    }
    
    func PressSelectGem2Btn() {
        PressSelectGemBtn(2)
    }
    
    func PressSelectGem3Btn() {
        PressSelectGemBtn(3)
    }
    
    func PressSelectGem4Btn() {
        PressSelectGemBtn(4)
    }
    
    func PressSelectGemBtn(Id: Int) {
        print("Pressed select gem\(Id)")
        if gameState == .SelectGemRank {
            switch Id {
            case 0:
                selectedGemRank = .Sliver
            case 1:
                selectedGemRank = .Fragment
            case 2:
                selectedGemRank = .Chunk
            case 3:
                selectedGemRank = .Cluster
            case 4:
                selectedGemRank = .Core
            default:
                break
            }
            
            for var color = 0; color < GemColor.vals.count; color++ {
                selectGemPanel.Btn(color)?.ChangeTextures("Gem\(GemColor.vals[color].colorName)\(Id)Button", buttonDepressedTexture: "Gem\(GemColor.vals[color].colorName)\(Id)ButtonActive", buttonDisabledTexture: "Gem\(GemColor.vals[color].colorName)\(Id)ButtonDisabled")
            }
            selectGemPanel.Btn(4)?.ChangeTextures("GemWhite\(Id)Button", buttonDepressedTexture: "GemWhite\(Id)ButtonActive", buttonDisabledTexture: "GemWhite\(Id)ButtonDisabled")
//            for var btn = 0; btn < selectGemPanel.btns.count; btn++ {
//                selectGemPanel.Btn(btn)?.iconSprite?.texture = SKTexture(imageNamed: selectGemPanel.Btn(btn)!.iconTexture!)
//            }
            gameState = .SelectGemColor
        }
            
        else if gameState == .SelectGemColor {
            switch Id {
            case 0:
                selectedGemColor = .Red
            case 1:
                selectedGemColor = .Yellow
            case 2:
                selectedGemColor = .Green
            case 3:
                selectedGemColor = .Blue
            case 4:
                selectedGemColor = GemColor.randomColor()
            default:
                break
            }
            
            if selectedGemColor != nil && selectedGemRank != nil {
                inv.CreateGem(selectedGemColor!, rank: selectedGemRank!)
            }
            
            CancelState()
        }
    }
    
    func SelectMapCell(cell: MapCellNode) {
        // Deselected the selected cell
        if cell === selectedMapCell {
            selectedMapCell!.selectedSprite.hidden = true
            selectedMapCell = nil
            print("Cell deselected")
            return
        }
        
        // Second cell selected, swap gems
        if selectedMapCell != nil {
            switch gameState {
            case .Default:
                SwapGems(cell, secondCell: selectedMapCell!)
                print("Two cells selected - Swapping gems")
            case .FuseGems:
                // TO DO: FuseGems(...)
                print("Two cells selected - Fusing gems")
                break
            default:
                break
            }
            CancelState()
            return
        }
        
        // Inventory slot and map cell selected, swap gems
        if selectedInventorySlot != nil {
            switch gameState {
            case .Default:
                SwapGems(cell, slot: selectedInventorySlot!)
                print("Cell and slot selected - Swapping gems")
            case .FuseGems:
                // TO DO: FuseGems(...)
                print("Cell and slot selected - Fusing gems")
                break
            default:
                break
            }
            CancelState()
            return
        }
        
        // Selected map cell does not contain a tower with a gem
        if cell.tower == nil || cell.tower!.gem == nil {
            print("Selected empty cell")
            return
        }
        
        // First cell selected
        selectedMapCell = cell
        cell.selectedSprite.hidden = false
        print("Cell selected")
    }
    
    func PressInventorySlot(slot: InventorySlotNode) {
        if gameState == .CreateTower {
            CancelState()
        }
        SelectInventorySlot(slot)
    }
    
    func SelectInventorySlot(slot: InventorySlotNode) {
        // Deselected the selected slot
        if slot === selectedInventorySlot {
            selectedInventorySlot!.selectedSprite.hidden = true
            selectedInventorySlot = nil
            print("Slot deselected")
            return
        }
        
        // Second slot selected, swap gems
        if selectedInventorySlot != nil {
            switch gameState {
            case .Default:
                SwapGems(slot, secondSlot: selectedInventorySlot!)
                print("Two slots selected - Swapping gems")
            case .FuseGems:
                // TO DO: FuseGems(...)
                print("Two slots selected - Swapping gems")
                break
            default:
                break
            }
            CancelState()
            return
        }
        
        // Inventory slot and map cell selected, swap gems
        if selectedMapCell != nil {
            switch gameState {
            case .Default:
                SwapGems(selectedMapCell!, slot: slot)
                print("Cell and slot selected - Swapping gems")
            case .FuseGems:
                // TO DO: FuseGems(...)
                print("Cell and slot selected - Swapping gems")
                break
            default:
                break
            }
            CancelState()
            return
        }
        
        // Selected inventory slot does not contain a gem
        if slot.gem == nil {
            print("Selected empty slot")
            return
        }
        
        // First slot selected
        selectedInventorySlot = slot
        slot.selectedSprite.hidden = false
        print("Slot selected")
    }
    
    func SwapGems(firstCell: MapCellNode, secondCell: MapCellNode) {
        if firstCell.tower != nil && secondCell.tower != nil {
            let tempGem: GemItem? = firstCell.tower?.gem
            tempGem?.removeFromParent()
            
            secondCell.tower?.gem?.removeFromParent()
            firstCell.tower?.gem = secondCell.tower?.gem
            if firstCell.tower?.gem != nil {
                firstCell.tower?.gem?.position = CGPointMake(firstCell.tower!.position.x, firstCell.tower!.position.y + gemOffset)
                firstCell.tower?.addChild(firstCell.tower!.gem!)
                //print("First cell: (\(firstCell.tower?.gem?.position.x), \(firstCell.tower?.gem?.position.y))")
            }
            
            secondCell.tower?.gem = tempGem
            if tempGem != nil {
                secondCell.tower?.gem?.position = CGPointMake(secondCell.tower!.position.x, secondCell.tower!.position.y + gemOffset)
                secondCell.tower?.addChild(tempGem!)
                //print("Second cell: (\(secondCell.tower?.gem?.position.x), \(secondCell.tower?.gem?.position.y))")
            }
        }
    }
    
    func SwapGems(firstSlot: InventorySlotNode, secondSlot: InventorySlotNode) {
        let tempGem: GemItem? = firstSlot.gem
        tempGem?.removeFromParent()
        
        secondSlot.gem?.removeFromParent()
        firstSlot.gem = secondSlot.gem
        if firstSlot.gem != nil {
            firstSlot.gem!.position = CGPointMake(0, 0)
            firstSlot.addChild(firstSlot.gem!)
            //print("First slot: (\(firstSlot.gem?.position.x), \(firstSlot.gem?.position.y))")
        }
        
        secondSlot.gem = tempGem
        if tempGem != nil {
            secondSlot.gem!.position = CGPointMake(0, 0)
            secondSlot.addChild(tempGem!)
            //print("Second slot: (\(secondSlot.gem?.position.x), \(secondSlot.gem?.position.y))")
        }
    }
    
    func SwapGems(cell: MapCellNode, slot: InventorySlotNode) {
        if cell.tower != nil {
            let tempGem: GemItem? = cell.tower?.gem
            tempGem?.removeFromParent()
            
            slot.gem?.removeFromParent()
            cell.tower?.gem = slot.gem
            if cell.tower?.gem != nil {
                cell.tower?.gem?.position = CGPointMake(cell.tower!.position.x, cell.tower!.position.y + gemOffset)
                cell.tower?.addChild(cell.tower!.gem!)
                //print("First cell: (\(firstCell.tower?.gem?.position.x), \(firstCell.tower?.gem?.position.y))")
            }
            
            slot.gem = tempGem
            if tempGem != nil {
                slot.gem!.position = CGPointMake(0, 0)
                slot.addChild(tempGem!)
                //print("Second slot: (\(secondSlot.gem?.position.x), \(secondSlot.gem?.position.y))")
            }
        }
    }
    
    func CancelState() {
        switch gameState {
        case .Default:
            if selectedMapCell != nil {
                selectedMapCell!.selectedSprite.hidden = true
                selectedMapCell = nil
            }
            if selectedInventorySlot != nil {
                selectedInventorySlot!.selectedSprite.hidden = true
                selectedInventorySlot = nil
            }
        case .CreateTower:
            // Cancel Create Tower state
            createTowerBtn.ToggleState()
            createTowerBtn.Release()
        case .SelectGemRank:
            // Cancel Create Gem state
            createGemBtn.ToggleState()
            createGemBtn.Release()
            selectGemPanel.Hide()
        case .SelectGemColor:
            // Cancel Create Gem state
            createGemBtn.ToggleState()
            createGemBtn.Release()
            selectGemPanel.Hide()
        case .FuseGems:
            // Cancel Fuse Gems state
            fuseGemsBtn.ToggleState()
            fuseGemsBtn.Release()
        }
        
        gameState = .Default
    }
    
    func StartWaveTimer(time: Double) {
        removeActionForKey("waveTimer")
        
        timerCounter = time + timerTickDuration
        let minutes = Int(floor(timerCounter)) / 60
        let seconds = Int(floor(timerCounter)) % 60
        let timerText = "\(String(format: "%01d", minutes)):\(String(format: "%02d", seconds))"
        timerLabel.text = timerText
        
        let waitAction = SKAction.waitForDuration(timerTickDuration)
        let tickAction = SKAction.runBlock {
            self.TickWaveTimer()
        }
        runAction(SKAction.sequence([waitAction, tickAction]), withKey: "waveTimer")
    }
    
    private func TickWaveTimer() {
        if timerCounter > 0 {
            timerCounter -= timerTickDuration
            let minutes = Int(floor(timerCounter)) / 60
            let seconds = Int(floor(timerCounter)) % 60
            let timerText = "\(String(format: "%01d", minutes)):\(String(format: "%02d", seconds))"
            timerLabel.text = timerText
            
            let waitAction = SKAction.waitForDuration(timerTickDuration)
            let tickAction = SKAction.runBlock {
                self.TickWaveTimer()
            }
            runAction(SKAction.sequence([waitAction, tickAction]), withKey: "waveTimer")
        }
        else {
            StartNextWave()
        }
    }
    
    func SetWaveLabel() {
        var activeEnemies: Int = 0
        var incomingEnemies: Int = 0
        
        for round in rounds {
            for wave in round.activeWaves {
                activeEnemies += wave.enemies.count
                incomingEnemies += wave.incomingEnemies
            }
        }
        
        let waveText = "\(String(format: "%02d", activeEnemies))/\(String(format: "%02d", incomingEnemies))"
        waveLabel.text = waveText
    }
    
    func SetScore(amt: Double) {
        playerScore = amt
        scoreLabel.text = String(format: "%06.0f", playerScore)
        
        print("Set playerScore to: \(playerScore)")
    }
    
    func ModifyScore(amt: Double) {
        playerScore += amt
        scoreLabel.text = String(format: "%06.0f", playerScore)
        
        print("Modified playerScore by: \(amt), now at: \(playerScore)")
    }
    
    func SetPlayerHp(amt: Int) {
        playerHp = amt
        healthLabel.text = String(format: "%02d", playerHp)
        
        print("Set playerHp to: \(playerHp)")
    }
    
    func ModifyPlayerHp(amt: Int) {
        playerHp += amt
        // Don't show negative values for playerHp
        if playerHp >= 0 {
            healthLabel.text = String(format: "%02d", playerHp)
        }
        // Check if the player has run out of health
        if amt < 0 && playerHp <= 0 {
            // TO DO: Player loses game
            print("YOU LOST")
        }
        
        print("Modified playerHp by: \(amt), now at: \(playerHp)")
    }
    
    func SetPlayerEnergy(amt: Double) {
        playerEnergy = amt
        energyLabel.text = String(format: "%03.0f", playerEnergy)
        
        print("Set playerEnergy to: \(playerEnergy)")
    }
    
    func ModifyPlayerEnergy(amt: Double) {
        playerEnergy += amt
        energyLabel.text = String(format: "%03.0f", playerEnergy)
        
        print("Modified playerEnergy by: \(amt), now at: \(playerEnergy)")
    }
}
