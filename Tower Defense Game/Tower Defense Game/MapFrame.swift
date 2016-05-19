//
//  GameMap.swift
//  Tower Defense Game
//
//  Created by William Elmes on 3/4/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

let mapWidth = 18
let mapHeight = 14

enum Tileset: String {
    case Sand = "Sand"
}

class MapFrame: SKNode {
    var basePosition: CGPoint
    var cells = [[MapCellNode]]()
    var startCell: MapCellNode?
    var endCell: MapCellNode?
    
    var towers = [TowerUnit]()
    let endPlatformSprite = SKSpriteNode(imageNamed: "EndPlatform")
    let endPoolSprite = SKSpriteNode(imageNamed: "EndPool00")
    var endSplashSprites = [SKSpriteNode]()
    var endSplashFrameTextures = [SKTexture]()
    let numEndSplashFrameTextures = 21
    
    override init() {
        basePosition = CGPointMake(cellWidth * 1.5, cellHeight * 0.5)
        
        super.init()
        
        // Initialize the map cells
        //print("cellWidth=\(cellWidth)")
        //print("cellWidth: \(cellWidth), position.x: \(position.x), position.y: \(position.y)")
        for var row = 0; row < mapHeight; row++ {
            var mapRow = [MapCellNode]()
            for var col = 0; col < mapWidth; col++ {
                let cell = MapCellNode(highlightTexture: "HighlightLine", selectedTexture: "HighlightDotted")
                cell.position = CGPointMake(basePosition.x + CGFloat(col) * cellWidth, basePosition.y + CGFloat(row) * cellHeight)
                //print("cell[\(row)][\(col)] = (\(cell.position.x), \(cell.position.y))")
                cell.AddTower = AddTower
                addChild(cell)
                mapRow.append(cell)
            }
            cells.append(mapRow)
        }
        
        // Initialize the map cells' adjacent cells
        for var row = 0; row < mapHeight; row++ {
            for var col = 0; col < mapWidth; col++ {
                if row > 0 {
                    cells[row][col].sCell = cells[row - 1][col]
                    if col > 0 {
                        cells[row][col].swCell = cells[row - 1][col - 1]
                    }
                    if col < mapWidth - 1 {
                        cells[row][col].seCell = cells[row - 1][col + 1]
                    }
                }
                if row < mapHeight - 1 {
                    cells[row][col].nCell = cells[row + 1][col]
                    if col > 0 {
                        cells[row][col].nwCell = cells[row + 1][col - 1]
                    }
                    if col < mapWidth - 1 {
                        cells[row][col].neCell = cells[row + 1][col + 1]
                    }
                }
                if col > 0 {
                    cells[row][col].wCell = cells[row][col - 1]
                }
                if col < mapWidth - 1 {
                    cells[row][col].eCell = cells[row][col + 1]
                }
            }
        }
        
        DrawGrid()
        
        endPlatformSprite.zPosition = 10
        endPoolSprite.zPosition = 20
        addChild(endPlatformSprite)
        addChild(endPoolSprite)
        
        var poolFrameTextures = [SKTexture]()
        poolFrameTextures.append(SKTexture(imageNamed: "EndPool00"))
        poolFrameTextures.append(SKTexture(imageNamed: "EndPool01"))
        let animAction = SKAction.repeatActionForever(SKAction.animateWithTextures(poolFrameTextures, timePerFrame: 0.5))
        endPoolSprite.runAction(animAction)
        
        for var f = 0; f < numEndSplashFrameTextures; f++ {
            endSplashFrameTextures.append(SKTexture(imageNamed: "EndPool\(String(format: "%02d", f))"))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func DrawGrid() {
        for var col = 0; col <= mapWidth; col++ {
            let linePath = CGPathCreateMutable()
            let gridLine = SKShapeNode(path: linePath)
            CGPathMoveToPoint(linePath, nil, basePosition.x + cellWidth * (CGFloat(col) - 0.5), basePosition.y - cellHeight * 0.5)
            CGPathAddLineToPoint(linePath, nil, basePosition.x + cellWidth * (CGFloat(col) - 0.5), basePosition.y + cellHeight * (CGFloat(mapHeight) - 0.5))
            
            gridLine.path = linePath
            gridLine.lineWidth = 2
            gridLine.strokeColor = SKColor.blackColor()
            gridLine.zPosition = 1
            addChild(gridLine)
        }
        
        for var row = 0; row <= mapHeight; row++ {
            let linePath = CGPathCreateMutable()
            let gridLine = SKShapeNode(path: linePath)
            CGPathMoveToPoint(linePath, nil, basePosition.x - cellWidth * 0.5, basePosition.y + cellHeight * (CGFloat(row) - 0.5))
            CGPathAddLineToPoint(linePath, nil, basePosition.x + cellWidth * (CGFloat(mapWidth) - 0.5), basePosition.y + cellHeight * (CGFloat(row) - 0.5))
            
            gridLine.path = linePath
            gridLine.lineWidth = 2
            gridLine.strokeColor = SKColor.blackColor()
            gridLine.zPosition = 1
            addChild(gridLine)
        }
    }
    
    func Load(tileset: Tileset, pathMap: [[Bool]], buildMap: [[Bool]], start: (x: Int, y: Int), end: (x: Int, y: Int)) -> Bool {
        print("Loading tileset...")
        
        // Reset the cells' tile type
        for var row = 0; row < mapHeight; row++ {
            for var col = 0; col < mapWidth; col++ {
                cells[row][col].tileType = 0
            }
        }
        
        for var row = 0; row < mapHeight; row++ {
            for var col = 0; col < mapWidth; col++ {
                cells[row][col].pathable = pathMap[row][col]
                cells[row][col].buildable = buildMap[row][col]
                if cells[row][col].pathable {
                    if col == 0 || col == mapWidth - 1 {
                        cells[row][col].tileType += 10
                    }
                    if row == 0 || row == mapHeight - 1 {
                        cells[row][col].tileType += 10
                    }
                }
                else {
                    cells[row][col].tileType += 100
                    cells[row][col].nCell?.tileType += 10
                    cells[row][col].wCell?.tileType += 10
                    cells[row][col].eCell?.tileType += 10
                    cells[row][col].sCell?.tileType += 10
                    cells[row][col].nwCell?.tileType += 1
                    cells[row][col].neCell?.tileType += 1
                    cells[row][col].swCell?.tileType += 1
                    cells[row][col].seCell?.tileType += 1
                }
            }
        }
        
        for var row = 0; row < mapHeight; row++ {
            for var col = 0; col < mapWidth; col++ {
                cells[row][col].SetTile(tileset)
            }
        }
        
        endPlatformSprite.position = cells[end.y][end.x].position
        endPoolSprite.position = endPlatformSprite.position
        endPoolSprite.position.y += 14
        
        print("Tileset loaded!")
        
        return SetPathing(start, endCoords: end)
    }
    
    func SetPathing(startCoords: (x: Int, y: Int), endCoords: (x: Int, y: Int)) -> Bool {
        print("Setting pathing...")
        
        if cells.count != 0 && (startCoords.x >= 0 && startCoords.x < mapWidth) && (startCoords.y >= 0 && startCoords.y < mapHeight) && (endCoords.x >= 0 && endCoords.x < mapWidth) && (endCoords.y >= 0 && endCoords.y < mapHeight) {
            startCell = cells[startCoords.y][startCoords.x]
            endCell = cells[endCoords.y][endCoords.x]
            //print("startCell[\(startCoords.y)][\(startCoords.x)]: \(startCell == nil)")
            //print("endCell[\(endCoords.y)][\(endCoords.x)]: \(endCell == nil)")
            
            for var row = 0; row < mapHeight; row++ {
                for var col = 0; col < mapWidth; col++ {
                    var deltaX = col - startCoords.x
                    var deltaY = row - startCoords.y
                    cells[row][col].startDist = sqrt(Double(deltaX * deltaX + deltaY * deltaY))
                    deltaX = col - endCoords.x
                    deltaY = row - endCoords.y
                    cells[row][col].endDist = sqrt(Double(deltaX * deltaX + deltaY * deltaY))
                }
            }
            
            print("Pathing set!")
            
            return UpdatePathing()
            //print("\(startCell!.pathWeight) \(Direction.vals[startCell!.pathDir!.rawValue])")
        }
        else {
            print("ERROR: SetPathing(startCoords:(\(startCoords.x), \(startCoords.y)), endCoords:(\(endCoords.x), \(endCoords.y)))")
            return false
        }
    }
    
    func UpdatePathing() -> Bool {
        print("Updating pathing...")
        
        if cells.count == 0 || startCell == nil || endCell == nil {
            print("ERROR: UpdatePathing")
            return false
        }
        
        // Reset pathing
        for var row = 0; row < mapHeight; row++ {
            for var col = 0; col < mapWidth; col++ {
                cells[row][col].parentCell = nil
                cells[row][col].pathDir = nil
                cells[row][col].pathDist = 0
            }
        }
        
        //print("startCell: \(startCell == nil)")
        //print("endCell: \(endCell == nil)")
        
        var openList = [MapCellNode]()
        var closedList = [MapCellNode]()
        
        endCell!.pathDist = 0
        openList.append(endCell!)
        closedList.append(endCell!)
        
        while !openList.isEmpty {
            let currCell = openList.removeFirst()
            
            //            let dirLabel = SKLabelNode(fontNamed: "Verdana-Bold")
            //            let dirText: String
            //            if currCell.pathDir == nil {
            //                dirText = "END"
            //            }
            //            else {
            //                dirText = Direction.vals[currCell.pathDir!.rawValue]
            //            }
            //            dirLabel.text = dirText
            //            dirLabel.fontColor = SKColor.blackColor()
            //            dirLabel.position = CGPointMake(currCell.cellSprite.position.x, currCell.cellSprite.position.y + 5)
            //            dirLabel.zPosition = 5
            //            addChild(dirLabel)
            
            if currCell.nCell != nil && currCell.nCell!.pathable && !closedList.contains(currCell.nCell!) {
                currCell.nCell!.parentCell = currCell
                currCell.nCell!.pathDist = currCell.pathDist + 1
                currCell.nCell!.pathDir = .S
                openList.append(currCell.nCell!)
                closedList.append(currCell.nCell!)
            }
            if currCell.wCell != nil && currCell.wCell!.pathable && !closedList.contains(currCell.wCell!) {
                currCell.wCell!.parentCell = currCell
                currCell.wCell!.pathDist = currCell.pathDist + 1
                currCell.wCell!.pathDir = .E
                openList.append(currCell.wCell!)
                closedList.append(currCell.wCell!)
            }
            if currCell.eCell != nil && currCell.eCell!.pathable && !closedList.contains(currCell.eCell!) {
                currCell.eCell!.parentCell = currCell
                currCell.eCell!.pathDist = currCell.pathDist + 1
                currCell.eCell!.pathDir = .W
                openList.append(currCell.eCell!)
                closedList.append(currCell.eCell!)
            }
            if currCell.sCell != nil && currCell.sCell!.pathable && !closedList.contains(currCell.sCell!) {
                currCell.sCell!.parentCell = currCell
                currCell.sCell!.pathDist = currCell.pathDist + 1
                currCell.sCell!.pathDir = .N
                openList.append(currCell.sCell!)
                closedList.append(currCell.sCell!)
            }
            
            openList.sortInPlace()
        }
        
        print("Pathing updated!")
        
        return CheckPathing(nil)
    }
    
    func CheckPathing(testCell: MapCellNode?) -> Bool {
        //print("Checking pathing...")
        if cells.count == 0 || startCell == nil || endCell == nil {
            print("ERROR: CheckPathing")
            return false
        }
        
        var openList = [MapCellNode]()
        var closedList = [MapCellNode]()
        
        openList.append(endCell!)
        closedList.append(endCell!)
        
        while !openList.isEmpty {
            let currCell = openList.removeFirst()
            
            if currCell === startCell {
                return true
            }
            
            if currCell.nCell != nil && (currCell.nCell!.pathable && currCell.nCell! !== testCell) && !closedList.contains(currCell.nCell!) {
                openList.append(currCell.nCell!)
                closedList.append(currCell.nCell!)
            }
            if currCell.wCell != nil && (currCell.wCell!.pathable && currCell.wCell! !== testCell) && !closedList.contains(currCell.wCell!) {
                openList.append(currCell.wCell!)
                closedList.append(currCell.wCell!)
            }
            if currCell.eCell != nil && (currCell.eCell!.pathable && currCell.eCell! !== testCell) && !closedList.contains(currCell.eCell!) {
                openList.append(currCell.eCell!)
                closedList.append(currCell.eCell!)
            }
            if currCell.sCell != nil && (currCell.sCell!.pathable && currCell.sCell! !== testCell) && !closedList.contains(currCell.sCell!) {
                openList.append(currCell.sCell!)
                closedList.append(currCell.sCell!)
            }
        }
        
        return false
    }
    
    func EnemyEndAnimation() {
        let splashSprite = SKSpriteNode(imageNamed: "EndPool00")
        splashSprite.position = endPoolSprite.position
        splashSprite.zPosition = 400
        
        endSplashSprites.append(splashSprite)
        addChild(splashSprite)
        
        let animAction = SKAction.animateWithTextures(endSplashFrameTextures, timePerFrame: 0.05)
        let animEndAction = SKAction.runBlock {
            let i = self.endSplashSprites.indexOf(splashSprite)
            if i != nil {
                self.endSplashSprites.removeAtIndex(i!)
            }
            splashSprite.removeFromParent()
        }
        splashSprite.runAction(SKAction.sequence([animAction, animEndAction]))
    }
    
    func SetPressedAction(action: (MapCellNode) -> Void) {
        for var row = 0; row < mapHeight; row++ {
            for var col = 0; col < mapWidth; col++ {
                cells[row][col].pressedAction = action
            }
        }
    }
    
    func CreateTower(cell: MapCellNode) {
        if !cell.buildable {
            print("Cannot build a tower there")
        }
        else if cell === startCell || cell === endCell || !CheckPathing(cell) {
            print("Must leave an open path to the end")
        }
        else {
            cell.CreateTower()
            UpdatePathing()
        }
    }
    
    func AddTower(tower: TowerUnit) {
        print("Added new tower to map towers array...")
        
        towers.append(tower)
    }
    
    func StartTowerTargetSearch() {
        print("Beginning tower target search for \(towers.count) towers")
        
        for tower in towers {
            tower.SearchForTarget()
        }
    }
//    
//    func StopTowerTargetSearch() {
//        if towerTargettingEnabled {
//            print("Stopping tower targettting loop...")
//        
//            removeActionForKey("towerTargettingLoop")
//            towerTargettingEnabled = false
//        }
//    }
//    
//    private func AcquireTowersTargets() {
//        if activeRound == nil {
//            return
//        }
//        
//        //print("Acquiring targets for \(towers.count) towers")
//        for tower in towers {
//            if tower.isAttacking == false {
//                let enemiesInRange = activeRound!.GetEnemiesInRange(tower)
//                //print("Tower not attacking - \(enemiesInRange.count) enemies in range...")
//                tower.AcquireTarget(enemiesInRange)
//            }
//        }
//    }
}

class MapCellNode: SKNode, Comparable {
    // Adjacent cells
    var nCell: MapCellNode?
    var eCell: MapCellNode?
    var sCell: MapCellNode?
    var wCell: MapCellNode?
    var nwCell: MapCellNode?
    var neCell: MapCellNode?
    var swCell: MapCellNode?
    var seCell: MapCellNode?
    
    // Cell constants for current map
    var pathable = true
    var buildable = true
    var startDist: Double = 0
    var endDist: Double = 0
    var tileType: Int = 0
    
    // Pathing variables
    var parentCell: MapCellNode?
    var pathDir: Direction?
    var pathDist: Double = 0

    // Tower
    var tower: TowerUnit?
    var AddTower: ((TowerUnit) -> Void)?

    // UI
    var pressedAction: ((MapCellNode) -> Void)?
    let tileSprite: SKSpriteNode
    let highlightSprite: SKSpriteNode
    let selectedSprite: SKSpriteNode
    
    init(highlightTexture: String, selectedTexture: String) {
        tileSprite = SKSpriteNode(imageNamed: "SandClosed")
        highlightSprite = SKSpriteNode(imageNamed: highlightTexture)
        highlightSprite.zPosition = 200
        selectedSprite = SKSpriteNode(imageNamed: selectedTexture)
        selectedSprite.zPosition = 200
        
        super.init()
        
        addChild(tileSprite)
        addChild(highlightSprite)
        addChild(selectedSprite)
        highlightSprite.hidden = true
        selectedSprite.hidden = true
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
            
            if(tileSprite.containsPoint(location)) {
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
            
            if(tileSprite.containsPoint(location)) {
                Press()
                Release()
            }
        }
    }
    
    // Depress the cell, highlighting it
    func Depress() {
        highlightSprite.hidden = false
    }
    
    // Release the cell, removing highlight
    func Release() {
        highlightSprite.hidden = true
    }
    
    // Trigger the cell's pressed action
    func Press() {
        pressedAction?(self)
    }
    
    func CreateTower() {
        if tower != nil || !buildable {
            print("ERROR: CreateTower")
            return
        }
        
        tower = TowerUnit()
        AddTower?(tower!)
        addChild(tower!)
        pathable = false
        buildable = false
    }
    
    func SetTile(tileset: Tileset) {
        if tileType >= 100 {
            // Closed
            SetClosedTile(tileset)
        }
        else if tileType >= 30 {
            // End
            Set3EdgeTile(tileset)
        }
        else if tileType >= 20 {
            // Corner
            // Path
            // Path corner
            Set2EdgeTile(tileset)
        }
        else if tileType >= 10 {
            // Edge
            // Inner edge
            // T corner
            Set1EdgeTile(tileset)
        }
        else if tileType > 0 {
            // 4 inner corner
            // 3 inner corner
            // 2 inner corner
            // Diagonal corner
            // Inner corner
            Set0EdgeTile(tileset)
        }
        else {
            // Open
            SetOpenTile(tileset)
        }
    }
    
    private func SetClosedTile(tileset: Tileset) {
        let tileTexture = "Closed"
        tileSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileTexture)")
    }
    
    private func Set3EdgeTile(tileset: Tileset) {
        let tileTexture = "End"
        var tileDir = ""
        
        // North end
        if sCell != nil && sCell!.pathable {
            tileDir += "N"
        }
            // South end
        else if nCell != nil && nCell!.pathable {
            tileDir += "S"
        }
            // West end
        else if eCell != nil && eCell!.pathable {
            tileDir += "W"
        }
            // East end
        else if wCell != nil && wCell!.pathable {
            tileDir += "E"
        }
        
        // Set the tile sprite texture
        tileSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileTexture)\(tileDir)")
    }
    
    private func Set2EdgeTile(tileset: Tileset) {
        var tileTexture = ""
        var tileDir = ""
        
        // North edge
        if nCell == nil || !nCell!.pathable {
            tileDir += "N"
        }
        // South edge
        if sCell == nil || !sCell!.pathable {
            tileDir += "S"
        }
        // West edge
        if wCell == nil || !wCell!.pathable {
            tileDir += "W"
        }
        // East edge
        if eCell == nil || !eCell!.pathable {
            tileDir += "E"
        }
        
        // Set the tile type
        switch tileDir {
        case "NW":
            if seCell == nil || !seCell!.pathable {
                tileTexture = "PathCorner"
            }
            else {
                tileTexture = "Corner"
            }
        case "NE":
            if swCell == nil || !swCell!.pathable {
                tileTexture = "PathCorner"
            }
            else {
                tileTexture = "Corner"
            }
        case "SW":
            if neCell == nil || !neCell!.pathable {
                tileTexture = "PathCorner"
            }
            else {
                tileTexture = "Corner"
            }
        case "SE":
            if nwCell == nil || !nwCell!.pathable {
                tileTexture = "PathCorner"
            }
            else {
                tileTexture = "Corner"
            }
        case "NS", "WE":
            tileTexture = "Path"
        default:
            break
        }
        
        // Set the tile sprite texture
        tileSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileTexture)\(tileDir)")
    }
    
    private func Set1EdgeTile(tileset: Tileset) {
        var tileTexture = ""
        var tileDir = ""
        
        // North edge
        if nCell == nil || !nCell!.pathable {
            tileDir += "N"
        }
        // South edge
        if sCell == nil || !sCell!.pathable {
            tileDir += "S"
        }
        // West edge
        if wCell == nil || !wCell!.pathable {
            tileDir += "W"
        }
        // East edge
        if eCell == nil || !eCell!.pathable {
            tileDir += "E"
        }
        
        // Set the tile type
        switch tileDir {
        case "N":
            if swCell == nil || !swCell!.pathable {
                if seCell == nil || !seCell!.pathable {
                    tileTexture = "TCorner"
                }
                else {
                    tileDir += "SW"
                    tileTexture = "InnerEdge"
                }
            }
            else if seCell == nil || !seCell!.pathable {
                tileDir += "SE"
                tileTexture = "InnerEdge"
            }
            else {
                tileTexture = "Edge"
            }
        case "S":
            if nwCell == nil || !nwCell!.pathable {
                if neCell == nil || !neCell!.pathable {
                    tileTexture = "TCorner"
                }
                else {
                    tileDir += "NW"
                    tileTexture = "InnerEdge"
                }
            }
            else if neCell == nil || !neCell!.pathable {
                tileDir += "NE"
                tileTexture = "InnerEdge"
            }
            else {
                tileTexture = "Edge"
            }
        case "W":
            if neCell == nil || !neCell!.pathable {
                if seCell == nil || !seCell!.pathable {
                    tileTexture = "TCorner"
                }
                else {
                    tileDir += "NE"
                    tileTexture = "InnerEdge"
                }
            }
            else if seCell == nil || !seCell!.pathable {
                tileDir += "SE"
                tileTexture = "InnerEdge"
            }
            else {
                tileTexture = "Edge"
            }
            
        case "E":
            if nwCell == nil || !nwCell!.pathable {
                if swCell == nil || !swCell!.pathable {
                    tileTexture = "TCorner"
                }
                else {
                    tileDir += "NW"
                    tileTexture = "InnerEdge"
                }
            }
            else if swCell == nil || !swCell!.pathable {
                tileDir += "SW"
                tileTexture = "InnerEdge"
            }
            else {
                tileTexture = "Edge"
            }
        default:
            break
        }
        
        // Set the tile sprite texture
        tileSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileTexture)\(tileDir)")
    }
    
    private func Set0EdgeTile(tileset: Tileset) {
        var tileTexture = ""
        var tileDir = ""
        
        // Set tile type and direction
        switch tileType {
            // One corner tile
        case 1:
            tileTexture = "Inner"
            if nwCell == nil || !nwCell!.pathable {
                tileDir = "NW"
            }
            else if neCell == nil || !neCell!.pathable {
                tileDir = "NE"
            }
            else if swCell == nil || !swCell!.pathable {
                tileDir = "SW"
            }
            else if seCell == nil || !seCell!.pathable {
                tileDir = "SE"
            }
            // Two corner tiles
        case 2:
            if nwCell == nil || !nwCell!.pathable {
                if neCell == nil || !neCell!.pathable {
                    tileTexture = "2Inner"
                    tileDir = "N"
                }
                else if swCell == nil || !swCell!.pathable {
                    tileTexture = "2Inner"
                    tileDir = "W"
                }
                else if seCell == nil || !seCell!.pathable {
                    tileTexture = "Diagonal"
                    tileDir = "NW"
                }
            }
            else if seCell == nil || !seCell!.pathable {
                if neCell == nil || !neCell!.pathable {
                    tileTexture = "2Inner"
                    tileDir = "E"
                }
                else if swCell == nil || !swCell!.pathable {
                    tileTexture = "2Inner"
                    tileDir = "S"
                }
            }
            else if (neCell == nil || !neCell!.pathable) && (swCell == nil || !swCell!.pathable) {
                tileTexture = "Diagonal"
                tileDir = "NE"
            }
            // Three corner tiles
        case 3:
            tileTexture = "3Inner"
            if nwCell == nil || !nwCell!.pathable {
                if neCell == nil || !neCell!.pathable {
                    if swCell == nil || !swCell!.pathable {
                        tileDir = "NW"
                    }
                    else if seCell == nil || !seCell!.pathable {
                        tileDir = "NE"
                    }
                }
                else if (swCell == nil || !seCell!.pathable) && (seCell == nil || !seCell!.pathable) {
                    tileDir = "SW"
                }
            }
            else if (neCell == nil || !neCell!.pathable) && (swCell == nil || !swCell!.pathable) && (seCell == nil || !seCell!.pathable) {
                tileDir = "SE"
            }
            // Four corner tiles
        case 4:
            if (nwCell == nil || !nwCell!.pathable) && (neCell == nil || !neCell!.pathable) && (swCell == nil || !swCell!.pathable) && (seCell == nil || !seCell!.pathable) {
                tileTexture = "4Inner"
                tileDir = ""
            }
        default:
            break
        }
        
        // Set the tile sprite texture
        tileSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileTexture)\(tileDir)")
    }
    
    private func SetOpenTile(tileset: Tileset) {
        // Tile and all surrounding tiles are pathable
        if pathable && tileType == 0 {
            let tileTexture = "Open"
            tileSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileTexture)")
        }
    }
}

func ==(lhs: MapCellNode, rhs: MapCellNode) -> Bool {
    return lhs.pathDist == rhs.pathDist && lhs.endDist == rhs.endDist && lhs.startDist == rhs.startDist
}

func <(lhs: MapCellNode, rhs: MapCellNode) -> Bool {
    if lhs.pathDist < rhs.pathDist {
        return true
    }
    if lhs.pathDist > rhs.pathDist {
        return false
    }
    
    if lhs.endDist < rhs.endDist {
        return true
    }
    if lhs.endDist > rhs.endDist {
        return false
    }
    
    if lhs.startDist < rhs.startDist {
        return true
    }
    if lhs.startDist > rhs.startDist {
        return false
    }
    
    return false
}

//class MapFrame: SKNode {
//    let basePos = CGPointMake(cellWidth, 0)
//    var cells = [[MapCellNode]]()
//    var startCell: MapCellNode?
//    var endCell: MapCellNode?
//    
//    override init() {
//        super.init()
//        
//        // Initialize the map cells
//        for var row = 0; row < mapHeight; row++ {
//            var mapRow = [MapCellNode]()
//            for var col = 0; col < mapWidth; col++ {
//                mapRow.insert(MapCellNode(highlightTexture: "CellHighlightLine", highlightAltTexture: "CellHighlightDotted"), atIndex: col)
//            }
//            cells.insert(mapRow, atIndex: row)
//        }
//        
//        // Initialize the map cells' sprites and adjacent cells
//        for var row = 0; row < mapHeight; row++ {
//            for var col = 0; col < mapWidth; col++ {
//                if row > 0 {
//                    cells[row][col].sCell = cells[row - 1][col]
//                    if col > 0 {
//                        cells[row][col].swCell = cells[row - 1][col - 1]
//                    }
//                    if col < mapWidth - 1 {
//                        cells[row][col].seCell = cells[row - 1][col + 1]
//                    }
//                }
//                if row < mapHeight - 1 {
//                    cells[row][col].nCell = cells[row + 1][col]
//                    if col > 0 {
//                        cells[row][col].nwCell = cells[row + 1][col - 1]
//                    }
//                    if col < mapWidth - 1 {
//                        cells[row][col].neCell = cells[row + 1][col + 1]
//                    }
//                }
//                if col > 0 {
//                    cells[row][col].wCell = cells[row][col - 1]
//                }
//                if col < mapWidth - 1 {
//                    cells[row][col].eCell = cells[row][col + 1]
//                }
//                
//                cells[row][col].mapCoords = (col, row)
//                cells[row][col].cellSprite = SKSpriteNode(imageNamed: "ButtonFace")
//                cells[row][col].cellSprite.position = CGPointMake(basePos.x + (CGFloat(col) + 0.5) * cellWidth, basePos.y + (CGFloat(row) + 0.5) * cellHeight)
//                cells[row][col].highlightSprite.position = cells[row][col].cellSprite.position
//                addChild(cells[row][col].cellSprite)
//            }
//        }
//        
//        DrawGrid()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func DrawGrid() {
//        for var col = 0; col <= mapWidth; col++ {
//            let linePath = CGPathCreateMutable()
//            let gridLine = SKShapeNode(path: linePath)
//            CGPathMoveToPoint(linePath, nil, basePos.x + cellWidth * CGFloat(col), basePos.y)
//            CGPathAddLineToPoint(linePath, nil, basePos.x + cellWidth * CGFloat(col), basePos.y + cellHeight * CGFloat(mapHeight))
//            
//            gridLine.path = linePath
//            gridLine.lineWidth = 2
//            gridLine.strokeColor = SKColor.blackColor()
//            gridLine.zPosition = 1
//            addChild(gridLine)
//        }
//        
//        for var row = 0; row <= mapHeight; row++ {
//            let linePath = CGPathCreateMutable()
//            let gridLine = SKShapeNode(path: linePath)
//            CGPathMoveToPoint(linePath, nil, basePos.x, basePos.y + cellHeight * CGFloat(row))
//            CGPathAddLineToPoint(linePath, nil, basePos.x + cellWidth * CGFloat(mapWidth), basePos.y + cellHeight * CGFloat(row))
//            
//            gridLine.path = linePath
//            gridLine.lineWidth = 2
//            gridLine.strokeColor = SKColor.blackColor()
//            gridLine.zPosition = 1
//            addChild(gridLine)
//        }
//    }
//
//    func Load(tileset: Tileset, pathMap: [[Bool]]) {
//        for var row = 0; row < mapHeight; row++ {
//            for var col = 0; col < mapWidth; col++ {
//                cells[row][col].tileTypeRating = 0
//            }
//        }
//        
//        for var row = 0; row < mapHeight; row++ {
//            for var col = 0; col < mapWidth; col++ {
//                cells[row][col].pathable = pathMap[row][col]
//                if cells[row][col].pathable {
//                    if col == 0 || col == mapWidth - 1 {
//                        cells[row][col].tileTypeRating += 10
//                    }
//                    if row == 0 || row == mapHeight - 1 {
//                        cells[row][col].tileTypeRating += 10
//                    }
//                }
//                else {
//                    cells[row][col].tileTypeRating += 100
//                    cells[row][col].nCell?.tileTypeRating += 10
//                    cells[row][col].wCell?.tileTypeRating += 10
//                    cells[row][col].eCell?.tileTypeRating += 10
//                    cells[row][col].sCell?.tileTypeRating += 10
//                    cells[row][col].nwCell?.tileTypeRating += 1
//                    cells[row][col].neCell?.tileTypeRating += 1
//                    cells[row][col].swCell?.tileTypeRating += 1
//                    cells[row][col].seCell?.tileTypeRating += 1
//                }
//            }
//        }
//        
//        for var row = 0; row < mapHeight; row++ {
//            for var col = 0; col < mapWidth; col++ {
//                cells[row][col].SetTile(tileset)
//            }
//        }
//    }
//
//    func SetPathing(startCoords: (Int, Int), endCoords: (Int, Int)) {
//        if cells.count != 0 && (startCoords.0 >= 0 && startCoords.0 < mapWidth) && (startCoords.1 >= 0 && startCoords.1 < mapHeight) && (endCoords.0 >= 0 && endCoords.0 < mapWidth) && (endCoords.1 >= 0 && endCoords.1 < mapHeight) {
//            startCell = cells[startCoords.1][startCoords.0]
//            endCell = cells[endCoords.1][endCoords.0]
//            
//            for var row = 0; row < mapHeight; row++ {
//                for var col = 0; col < mapWidth; col++ {
//                    var deltaX = cells[row][col].mapCoords!.col - startCell!.mapCoords!.col
//                    var deltaY = cells[row][col].mapCoords!.row - startCell!.mapCoords!.row
//                    cells[row][col].startDist = sqrt(Double(deltaX * deltaX + deltaY * deltaY))
//                    deltaX = cells[row][col].mapCoords!.col - endCell!.mapCoords!.col
//                    deltaY = cells[row][col].mapCoords!.row - endCell!.mapCoords!.row
//                    cells[row][col].endDist = sqrt(Double(deltaX * deltaX + deltaY * deltaY))
//                }
//            }
//            
//            UpdatePathing()
//            //print("\(startCell!.pathWeight) \(Direction.vals[startCell!.pathDir!.rawValue])")
//        }
//    }
//
//    func UpdatePathing() {
//        if cells.count == 0 || startCell == nil || endCell == nil {
//            return
//        }
//        
//        var openList = [MapCellNode]()
//        var closedList = [MapCellNode]()
//        
//        endCell!.parentCell = nil
//        endCell!.pathDist = 0
//        openList.append(endCell!)
//        closedList.append(endCell!)
//        
//        while !openList.isEmpty {
//            let currCell = openList.removeFirst()
//            
////            let dirLabel = SKLabelNode(fontNamed: "Verdana-Bold")
////            let dirText: String
////            if currCell.pathDir == nil {
////                dirText = "END"
////            }
////            else {
////                dirText = Direction.vals[currCell.pathDir!.rawValue]
////            }
////            dirLabel.text = dirText
////            dirLabel.fontColor = SKColor.blackColor()
////            dirLabel.position = CGPointMake(currCell.cellSprite.position.x, currCell.cellSprite.position.y + 5)
////            dirLabel.zPosition = 5
////            addChild(dirLabel)
//            
//            if currCell.nCell != nil && currCell.nCell!.pathable && !closedList.contains(currCell.nCell!) {
//                currCell.nCell!.parentCell = currCell
//                currCell.nCell!.pathDist = currCell.pathDist! + 1
//                currCell.nCell!.pathDir = .S
//                openList.append(currCell.nCell!)
//                closedList.append(currCell.nCell!)
//            }
//            if currCell.wCell != nil && currCell.wCell!.pathable && !closedList.contains(currCell.wCell!) {
//                currCell.wCell!.parentCell = currCell
//                currCell.wCell!.pathDist = currCell.pathDist! + 1
//                currCell.wCell!.pathDir = .E
//                openList.append(currCell.wCell!)
//                closedList.append(currCell.wCell!)
//            }
//            if currCell.eCell != nil && currCell.eCell!.pathable && !closedList.contains(currCell.eCell!) {
//                currCell.eCell!.parentCell = currCell
//                currCell.eCell!.pathDist = currCell.pathDist! + 1
//                currCell.eCell!.pathDir = .W
//                openList.append(currCell.eCell!)
//                closedList.append(currCell.eCell!)
//            }
//            if currCell.sCell != nil && currCell.sCell!.pathable && !closedList.contains(currCell.sCell!) {
//                currCell.sCell!.parentCell = currCell
//                currCell.sCell!.pathDist = currCell.pathDist! + 1
//                currCell.sCell!.pathDir = .N
//                openList.append(currCell.sCell!)
//                closedList.append(currCell.sCell!)
//            }
//            
//            openList.sortInPlace()
//        }
//    }
//}
//
//class MapCellNode: SKNode, Comparable {
//    var nCell: MapCellNode?
//    var eCell: MapCellNode?
//    var sCell: MapCellNode?
//    var wCell: MapCellNode?
//    var nwCell: MapCellNode?
//    var neCell: MapCellNode?
//    var swCell: MapCellNode?
//    var seCell: MapCellNode?
//    
//    var pathable = true
//    var parentCell: MapCellNode?
//    var pathDist: Double?
//    var startDist: Double?
//    var endDist: Double?
//    var pathDir: Direction?
//    var tileTypeRating = 0
//    var mapCoords: (col: Int, row: Int)?
//    
//    var enemyList = [EnemyUnit]()
//    
//    var highlightActiveTexture: String
//    var highlightSecondaryTexture: String
//    var pressedAction: (() -> Void)?
//    
//    var cellSprite = SKSpriteNode()
//    var highlightSprite: SKSpriteNode
//
//    init(highlightTexture: String, highlightAltTexture: String) {
//        highlightActiveTexture = highlightTexture
//        highlightSecondaryTexture = highlightAltTexture
//        highlightSprite = SKSpriteNode(imageNamed: highlightActiveTexture)
//        
//        super.init()
//        
//        userInteractionEnabled = true
//        highlightSprite.hidden = true
//        highlightSprite.zPosition = 200
//        addChild(highlightSprite)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        Depress()
//    }
//    
//    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        for touch in touches {
//            let location = touch.locationInNode(self)
//            
//            if(cellSprite.containsPoint(location)) {
//                Depress()
//            }
//            else {
//                Release()
//            }
//        }
//    }
//    
//    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        for touch in touches {
//            let location = touch.locationInNode(self)
//            
//            if(cellSprite.containsPoint(location)) {
//                Press()
//                Release()
//            }
//        }
//    }
//    
//    // Depress the cell, highlighting it
//    func Depress() {
//        highlightSprite.hidden = false
//        print("Depress")
//    }
//    
//    // Release the cell, removing highlight
//    func Release() {
//        highlightSprite.hidden = true
//        print("Release")
//    }
//    
//    // Trigger the cell's pressed action
//    func Press() {
//        pressedAction?()
//        print("Press")
//    }
//    
//    func SetTile(tileset: Tileset) {
//        if tileTypeRating >= 100 {
//            // Closed
//            SetClosedTile(tileset)
//        }
//        else if tileTypeRating >= 30 {
//            // End
//            Set3EdgeTile(tileset)
//        }
//        else if tileTypeRating >= 20 {
//            // Corner
//            // Path
//            // Path corner
//            Set2EdgeTile(tileset)
//        }
//        else if tileTypeRating >= 10 {
//            // Edge
//            // Inner edge
//            // T corner
//            Set1EdgeTile(tileset)
//        }
//        else if tileTypeRating > 0 {
//            // 4 inner corner
//            // 3 inner corner
//            // 2 inner corner
//            // Diagonal corner
//            // Inner corner
//            Set0EdgeTile(tileset)
//        }
//        else {
//            // Open
//            SetOpenTile(tileset)
//        }
//    }
//    
//    private func SetClosedTile(tileset: Tileset) {
//        // Tile is not pathable
//        if !pathable {
//            let tileType = "Closed"
//            cellSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileType)")
//        }
//    }
//    
//    private func Set3EdgeTile(tileset: Tileset) {
//        let tileType = "End"
//        var tileDir = ""
//        
//        // North end
//        if sCell != nil && sCell!.pathable {
//            tileDir += "N"
//        }
//            // South end
//        else if nCell != nil && nCell!.pathable {
//            tileDir += "S"
//        }
//            // West end
//        else if eCell != nil && eCell!.pathable {
//            tileDir += "W"
//        }
//            // East end
//        else if wCell != nil && wCell!.pathable {
//            tileDir += "E"
//        }
//        
//        // Set the tile sprite texture
//        cellSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileType)\(tileDir)")
//    }
//    
//    private func Set2EdgeTile(tileset: Tileset) {
//        var tileType: String?
//        var tileDir = ""
//        
//        // North edge
//        if nCell == nil || !nCell!.pathable {
//            tileDir += "N"
//        }
//        // South edge
//        if sCell == nil || !sCell!.pathable {
//            tileDir += "S"
//        }
//        // West edge
//        if wCell == nil || !wCell!.pathable {
//            tileDir += "W"
//        }
//        // East edge
//        if eCell == nil || !eCell!.pathable {
//            tileDir += "E"
//        }
//        
//        // Set the tile type
//        switch tileDir {
//        case "NW":
//            if seCell == nil || !seCell!.pathable {
//                tileType = "PathCorner"
//            }
//            else {
//                tileType = "Corner"
//            }
//        case "NE":
//            if swCell == nil || !swCell!.pathable {
//                tileType = "PathCorner"
//            }
//            else {
//                tileType = "Corner"
//            }
//        case "SW":
//            if neCell == nil || !neCell!.pathable {
//                tileType = "PathCorner"
//            }
//            else {
//                tileType = "Corner"
//            }
//        case "SE":
//            if nwCell == nil || !nwCell!.pathable {
//                tileType = "PathCorner"
//            }
//            else {
//                tileType = "Corner"
//            }
//        case "NS", "WE":
//            tileType = "Path"
//        default:
//            break
//        }
//        
//        // Set the tile sprite texture
//        if tileType != nil {
//            cellSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileType!)\(tileDir)")
//        }
//    }
//    
//    private func Set1EdgeTile(tileset: Tileset) {
//        var tileType: String?
//        var tileDir = ""
//        
//        // North edge
//        if nCell == nil || !nCell!.pathable {
//            tileDir += "N"
//        }
//        // South edge
//        if sCell == nil || !sCell!.pathable {
//            tileDir += "S"
//        }
//        // West edge
//        if wCell == nil || !wCell!.pathable {
//            tileDir += "W"
//        }
//        // East edge
//        if eCell == nil || !eCell!.pathable {
//            tileDir += "E"
//        }
//        
//        // Set the tile type
//        switch tileDir {
//        case "N":
//            if swCell == nil || !swCell!.pathable {
//                if seCell == nil || !seCell!.pathable {
//                    tileType = "TCorner"
//                }
//                else {
//                    tileDir += "SW"
//                    tileType = "InnerEdge"
//                }
//            }
//            else if seCell == nil || !seCell!.pathable {
//                tileDir += "SE"
//                tileType = "InnerEdge"
//            }
//            else {
//                tileType = "Edge"
//            }
//        case "S":
//            if nwCell == nil || !nwCell!.pathable {
//                if neCell == nil || !neCell!.pathable {
//                    tileType = "TCorner"
//                }
//                else {
//                    tileDir += "NW"
//                    tileType = "InnerEdge"
//                }
//            }
//            else if neCell == nil || !neCell!.pathable {
//                tileDir += "NE"
//                tileType = "InnerEdge"
//            }
//            else {
//                tileType = "Edge"
//            }
//        case "W":
//            if neCell == nil || !neCell!.pathable {
//                if seCell == nil || !seCell!.pathable {
//                    tileType = "TCorner"
//                }
//                else {
//                    tileDir += "NE"
//                    tileType = "InnerEdge"
//                }
//            }
//            else if seCell == nil || !seCell!.pathable {
//                tileDir += "SE"
//                tileType = "InnerEdge"
//            }
//            else {
//                tileType = "Edge"
//            }
//            
//        case "E":
//            if nwCell == nil || !nwCell!.pathable {
//                if swCell == nil || !swCell!.pathable {
//                    tileType = "TCorner"
//                }
//                else {
//                    tileDir += "NW"
//                    tileType = "InnerEdge"
//                }
//            }
//            else if swCell == nil || !swCell!.pathable {
//                tileDir += "SW"
//                tileType = "InnerEdge"
//            }
//            else {
//                tileType = "Edge"
//            }
//        default:
//            break
//        }
//        
//        // Set the tile sprite texture
//        if tileType != nil {
//            cellSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileType!)\(tileDir)")
//        }
//    }
//    
//    private func Set0EdgeTile(tileset: Tileset) {
//        var tileType: String?
//        var tileDir = ""
//        
//        // Set tile type and direction
//        switch tileTypeRating {
//        // One corner tile
//        case 1:
//            tileType = "Inner"
//            if nwCell == nil || !nwCell!.pathable {
//                tileDir = "NW"
//            }
//            else if neCell == nil || !neCell!.pathable {
//                tileDir = "NE"
//            }
//            else if swCell == nil || !swCell!.pathable {
//                tileDir = "SW"
//            }
//            else if seCell == nil || !seCell!.pathable {
//                tileDir = "SE"
//            }
//        // Two corner tiles
//        case 2:
//            if nwCell == nil || !nwCell!.pathable {
//                if neCell == nil || !neCell!.pathable {
//                    tileType = "2Inner"
//                    tileDir = "N"
//                }
//                else if swCell == nil || !swCell!.pathable {
//                    tileType = "2Inner"
//                    tileDir = "W"
//                }
//                else if seCell == nil || !seCell!.pathable {
//                    tileType = "Diagonal"
//                    tileDir = "NW"
//                }
//            }
//            else if seCell == nil || !seCell!.pathable {
//                if neCell == nil || !neCell!.pathable {
//                    tileType = "2Inner"
//                    tileDir = "E"
//                }
//                else if swCell == nil || !swCell!.pathable {
//                    tileType = "2Inner"
//                    tileDir = "S"
//                }
//            }
//            else if (neCell == nil || !neCell!.pathable) && (swCell == nil || !swCell!.pathable) {
//                tileType = "Diagonal"
//                tileDir = "NE"
//            }
//        // Three corner tiles
//        case 3:
//            tileType = "3Inner"
//            if nwCell == nil || !nwCell!.pathable {
//                if neCell == nil || !neCell!.pathable {
//                    if swCell == nil || !swCell!.pathable {
//                        tileDir = "NW"
//                    }
//                    else if seCell == nil || !seCell!.pathable {
//                        tileDir = "NE"
//                    }
//                }
//                else if (swCell == nil || !seCell!.pathable) && (seCell == nil || !seCell!.pathable) {
//                    tileDir = "SW"
//                }
//            }
//            else if (neCell == nil || !neCell!.pathable) && (swCell == nil || !swCell!.pathable) && (seCell == nil || !seCell!.pathable) {
//                tileDir = "SE"
//            }
//        // Four corner tiles
//        case 4:
//            if (nwCell == nil || !nwCell!.pathable) && (neCell == nil || !neCell!.pathable) && (swCell == nil || !swCell!.pathable) && (seCell == nil || !seCell!.pathable) {
//                tileType = "4Inner"
//                tileDir = ""
//            }
//        default:
//            break
//        }
//        
//        // Set the tile sprite texture
//        if tileType != nil {
//            cellSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileType!)\(tileDir)")
//        }
//    }
//    
//    private func SetOpenTile(tileset: Tileset) {
//        // Tile and all surrounding tiles are pathable
//        if pathable && tileTypeRating == 0 {
//            let tileType = "Open"
//            cellSprite.texture = SKTexture(imageNamed: "\(tileset.rawValue)\(tileType)")
//        }
//    }
//}
//
//func ==(lhs: MapCellNode, rhs: MapCellNode) -> Bool {
//    return lhs === rhs
//}
//
//func <=(lhs: MapCellNode, rhs: MapCellNode) -> Bool {
//    if lhs.pathDist < rhs.pathDist {
//        return true
//    }
//    if lhs.pathDist > rhs.pathDist {
//        return false
//    }
//    
//    if lhs.endDist < rhs.endDist {
//        return true
//    }
//    if lhs.endDist > rhs.endDist {
//        return false
//    }
//    
//    if lhs.startDist < rhs.startDist {
//        return true
//    }
//    if lhs.startDist > rhs.startDist {
//        return false
//    }
//    
//    return true
//}
//
//func <(lhs: MapCellNode, rhs: MapCellNode) -> Bool {
//    if lhs.pathDist < rhs.pathDist {
//        return true
//    }
//    if lhs.pathDist > rhs.pathDist {
//        return false
//    }
//    
//    if lhs.endDist < rhs.endDist {
//        return true
//    }
//    if lhs.endDist > rhs.endDist {
//        return false
//    }
//    
//    if lhs.startDist < rhs.startDist {
//        return true
//    }
//    if lhs.startDist > rhs.startDist {
//        return false
//    }
//    
//    return false
//}
//
//func >(lhs: MapCellNode, rhs: MapCellNode) -> Bool {
//    if lhs.pathDist < rhs.pathDist {
//        return false
//    }
//    if lhs.pathDist > rhs.pathDist {
//        return true
//    }
//    
//    if lhs.endDist < rhs.endDist {
//        return false
//    }
//    if lhs.endDist > rhs.endDist {
//        return true
//    }
//    
//    if lhs.startDist < rhs.startDist {
//        return false
//    }
//    if lhs.startDist > rhs.startDist {
//        return true
//    }
//    
//    return false
//}
//
//func >=(lhs: MapCellNode, rhs: MapCellNode) -> Bool {
//    if lhs.pathDist < rhs.pathDist {
//        return false
//    }
//    if lhs.pathDist > rhs.pathDist {
//        return true
//    }
//    
//    if lhs.endDist < rhs.endDist {
//        return false
//    }
//    if lhs.endDist > rhs.endDist {
//        return true
//    }
//    
//    if lhs.startDist < rhs.startDist {
//        return false
//    }
//    if lhs.startDist > rhs.startDist {
//        return true
//    }
//    
//    return true
//}
//
//extension _ArrayType where Generator.Element : Equatable{
//    mutating func removeObject(object : Self.Generator.Element) {
//        while let index = self.indexOf(object){
//            self.removeAtIndex(index)
//        }
//    }
//}