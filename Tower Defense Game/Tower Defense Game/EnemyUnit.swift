//
//  EnemyUnit.swift
//  Tower Defense Game
//
//  Created by William Elmes on 3/2/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

let enemyOffsetY: CGFloat = 0.4
let poisonTickInterval: Double = 1.0
let deathDespawnDelay: Double = 10.0

enum EnemyType: Int {
    case Skeleton = 0
    
    static let vals = ["Skeleton"]
    static let scale: [CGFloat] = [1.5]
}

enum EnemyAnimation: Int {
    case Walking = 0
    case Death
    
    static let vals = ["Walking", "Death"]
    static let numFrames: [Int] = [8, 9]
    static let timePerFrame: [Double] = [0.25, 0.1]
}

enum Direction: Int {
    case N = 0
    case E
    case S
    case W
    
    static let vals = ["N", "E", "S", "W"]
}

// Singleton to store all enemy animation frame textures
class EnemyAnimations {
    static let sharedInstance = EnemyAnimations()
    
    var frameTextures = [[[[SKTexture]]]]()
    
    private init(){
        for var type = 0; type < EnemyType.vals.count; type++ {
            let textureAtlas = SKTextureAtlas(named: EnemyType.vals[type])
            var animsArray = [[[SKTexture]]]()
            for var anim = 0; anim < EnemyAnimation.vals.count; anim++ {
                var dirsArray = [[SKTexture]]()
                for var dir = 0; dir < Direction.vals.count; dir++ {
                    var framesArray = [SKTexture]()
                    for var frame = 0; frame < EnemyAnimation.numFrames[anim]; frame++ {
                        let textureName = "\(EnemyType.vals[type])\(EnemyAnimation.vals[anim])\(Direction.vals[dir])\(String(format: "%02d", frame))"
                        framesArray.append(textureAtlas.textureNamed(textureName))
                    }
                    dirsArray.append(framesArray)
                }
                animsArray.append(dirsArray)
            }
            frameTextures.append(animsArray)
        }
    }
}

class EnemyUnit: SKNode {
    var unitType: EnemyType
    var currAnim: EnemyAnimation = .Walking
    var facingDir: Direction = .E
    var mapCell: MapCellNode?
    var travelDist: Double = 0
    var frameTextures = [SKTexture]()
    var actionsQueue = Array<((Direction) -> Void, Direction)>()
    let unitSprite: SKSpriteNode
    
    var maxHp: Double
    var currHp: Double
    var projectedHp: Double
    var baseArmor: Double
    var currArmor: Double
    var baseSpeed: Double
    var currSpeed: Double
    var baseScale: CGFloat
    var currScale: CGFloat
    
    var killBounty: Double
    var killScore: Double
    
    var slows = [Double]()
    var poisonTicks = [Double]()
    
    var attackedBy = [TowerUnit]()
    var parentWave: EnemyWave
    
    var impactSprites = [SKSpriteNode]()
    var slowSprite: SKSpriteNode?
    var poisonSprite: SKSpriteNode?
    
    init(wave: EnemyWave, enemyType: EnemyType, hp: Double, armor: Double, speed: Double, scale: CGFloat, bounty: Double, score: Double) {
        parentWave = wave
        unitType = enemyType
        
        maxHp = hp
        currHp = maxHp
        projectedHp = currHp
        baseArmor = armor
        currArmor = baseArmor
        baseSpeed = 0.5
        currSpeed = baseSpeed
        baseScale = EnemyType.scale[unitType.rawValue] * scale
        currScale = baseScale
        
        killBounty = bounty
        killScore = score
        
        frameTextures = EnemyAnimations.sharedInstance.frameTextures[unitType.rawValue][currAnim.rawValue][facingDir.rawValue]
        unitSprite = SKSpriteNode(texture: frameTextures[0])
        unitSprite.setScale(currScale)
        unitSprite.zPosition = 100
        
        super.init()
        
        addChild(unitSprite)
        hidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func BeginPathing(startCell: MapCellNode) {
        //position = startCell.convertPoint(startCell.position, toNode: game!.parent!)
        //position.x += cellWidth * 0.75
        //position.y += cellHeight * 0.25
        hidden = false
        
        //map!.startCell!.enemyList.append(self)
        //map!.startCell!.parent!.enemyList.append(self)
        mapCell = game!.map.startCell
        position = mapCell!.position//game!.map.convertPoint(mapCell!.position, fromNode: mapCell!)
        print("Enemy spawned at: (\(position.x), \(position.y))")
        //print("starting position: (\(position.x), \(position.y))")
        unitSprite.position.y += enemyOffsetY * currScale * 64
        
        SetAnim(.Walking, repeatAnim: true, newFacingDir: mapCell!.pathDir!)
        var xFactor: CGFloat = 0
        var yFactor: CGFloat = 0
        switch mapCell!.pathDir! {
        case .N:
            yFactor = 1
        case .S:
            yFactor = -1
        case .E:
            xFactor = 1
        case .W:
            xFactor = -1
        }
        let offset = CGVectorMake(cellWidth * xFactor, cellHeight * yFactor)
        let moveAction = SKAction.moveBy(offset, duration: (Double(cellWidth) / 64) * currSpeed)
        runAction(moveAction, completion: Move)
        travelDist++
    }
    
    func Move() {
        //mapCell!.enemyList.removeObject(self)
        mapCell = mapCell!.parentCell
        if mapCell! === game!.map.endCell! {
            //mapCell!.enemyList.removeObject(self)
            ReachEnd()
            return
        }
        
        SetAnim(.Walking, repeatAnim: true, newFacingDir: mapCell!.pathDir!)
        var xFactor: CGFloat = 0
        var yFactor: CGFloat = 0
        switch mapCell!.pathDir! {
        case .N:
            yFactor = 1
        case .S:
            yFactor = -1
        case .E:
            xFactor = 1
        case .W:
            xFactor = -1
        }
        let moveIncrement: CGFloat = cellWidth
        let offset = CGVectorMake(xFactor * cellWidth / moveIncrement, yFactor * cellHeight / moveIncrement)
        let moveAction = SKAction.moveBy(offset, duration: (Double(cellWidth / moveIncrement) / 64) * currSpeed)
        var moveActionSequence = [SKAction]()
        for var i: CGFloat = 0; i < moveIncrement; i++ {
            moveActionSequence.append(moveAction)
        }
        runAction(SKAction.sequence(moveActionSequence), completion: Move)
        travelDist++
    }
    
    private func SetAnim(newAnim: EnemyAnimation, repeatAnim: Bool, newFacingDir: Direction) {
        if currAnim != newAnim || facingDir != newFacingDir || !unitSprite.hasActions() {
            unitSprite.removeActionForKey("Anim")
            currAnim = newAnim
            facingDir = newFacingDir
            frameTextures = EnemyAnimations.sharedInstance.frameTextures[unitType.rawValue][currAnim.rawValue][facingDir.rawValue]
            var animAction = SKAction.animateWithTextures(frameTextures, timePerFrame: EnemyAnimation.timePerFrame[currAnim.rawValue] * currSpeed)
            if repeatAnim {
                animAction = SKAction.repeatActionForever(animAction)
            }
            unitSprite.runAction(animAction, withKey: "Anim")
        }
    }
    
    func ReachEnd() {
        game!.map.EnemyEndAnimation()
        
        removeAllActions()
        unitSprite.removeAllActions()
        SetAnim(.Death, repeatAnim: false, newFacingDir: facingDir)
        
        poisonTicks.removeAll()
        poisonSprite?.removeAllActions()
        poisonSprite?.removeFromParent()
        poisonSprite = nil
        
        slows.removeAll()
        slowSprite?.removeAllActions()
        slowSprite?.removeFromParent()
        slowSprite = nil
        
        parentWave.EnemyKilled(self)
        for attacker in attackedBy {
            attacker.TargetKilled(self)
        }
        
        let waitAction = SKAction.waitForDuration(1)
        let despawnAction = SKAction.runBlock {
            self.Despawn()
        }
        runAction(SKAction.sequence([waitAction, despawnAction]))
    }
    
    func Kill(despawnDelay: Double = deathDespawnDelay) {
        removeAllActions()
        unitSprite.removeAllActions()
        SetAnim(.Death, repeatAnim: false, newFacingDir: facingDir)
        
        poisonTicks.removeAll()
        poisonSprite?.removeAllActions()
        poisonSprite?.removeFromParent()
        poisonSprite = nil
        
        slows.removeAll()
        slowSprite?.removeAllActions()
        slowSprite?.removeFromParent()
        slowSprite = nil
        
        game!.ModifyPlayerEnergy(killBounty)
        game!.ModifyScore(killScore)
        
        parentWave.EnemyKilled(self)
        for attacker in attackedBy {
            attacker.TargetKilled(self)
        }
        
        let waitAction = SKAction.waitForDuration(despawnDelay)
        let despawnAction = SKAction.runBlock {
            self.Despawn()
        }
        runAction(SKAction.sequence([waitAction, despawnAction]))
    }
    
    func Despawn() {
        removeFromParent()
    }
    
    func GetAttacked(attacker: TowerUnit) {
        if !attackedBy.contains(attacker) {
            attackedBy.append(attacker)
        }
    }
    
    func OutrangedAttacker(attacker: TowerUnit) {
        let i = attackedBy.indexOf(attacker)
        if i != nil {
            attackedBy.removeAtIndex(i!)
            //print("Removed attack from enemy attacked by list")
        }
    }
    
    // TO DO: Move Kill() function into separate function
    //  TakeDamage(...) runs on tower projectile launch
    //  CheckKill() runs on tower projectile impact
    func TakeDamage(amount: Double, armorBypass: Double) {
        if currHp <= 0 {
            return
        }
        
        let mitigatedAmount = amount - currArmor * (1.0 - armorBypass)
        currHp -= mitigatedAmount
        
        print("Dealt \(mitigatedAmount) damage to enemy")
        
        if currHp <= 0 {
            currHp = 0
            Kill()
        }
    }
    
    func ProjectDamage(amount: Double, armorBypass: Double) {
        let mitigatedAmount = amount - currArmor * (1.0 - armorBypass)
        projectedHp -= mitigatedAmount
        
        //print("Projected \(mitigatedAmount) damage to enemy")
    }
    
    func UpdateMovementSpeed() {
        currSpeed = baseSpeed
        var activeSlow: Double = 1.0
        for slow in slows {
            if slow < activeSlow {
                activeSlow = slow
            }
        }
        currSpeed /= activeSlow
        // TO DO: Adjust speed of in-progress move actions
    }
    
    func ApplySlow(slow: Double, duration: Double) {
        slows.append(slow)
        UpdateMovementSpeed()
        
        if slowSprite == nil {
            slowSprite = SKSpriteNode(texture: GemColor.vals[GemColor.Blue.rawValue].effectFramesTextures![0])
            addChild(slowSprite!)
            slowSprite!.position.y -= 5
            slowSprite!.zPosition = 80
            slowSprite!.setScale(1.5)
            
            let slowAnimAction = SKAction.animateWithTextures(GemColor.vals[GemColor.Blue.rawValue].effectFramesTextures!, timePerFrame: 0.05)
            slowSprite!.runAction(SKAction.repeatActionForever(slowAnimAction))
        }
        
        let waitAction = SKAction.waitForDuration(duration)
        let expireAction = SKAction.runBlock {
            let i = self.slows.indexOf(slow)
            if i != nil {
                self.slows.removeAtIndex(i!)
                self.UpdateMovementSpeed()
            }
            if self.slowSprite != nil && self.slows.count == 0 {
                self.slowSprite!.removeFromParent()
                self.slowSprite = nil
            }
        }
        runAction(SKAction.sequence([waitAction, expireAction]))
    }
    
    func ApplyPoison(dmg: Double, numTicks: Int) {
        // If not already poison, begin the poison tick loop
        if poisonTicks.count == 0 {
            let waitAction = SKAction.waitForDuration(poisonTickInterval)
            let tickAction = SKAction.runBlock {
                self.TickPoison()
            }
            runAction(SKAction.sequence([waitAction, tickAction]))
        }
        
        // Create the poison effect sprite
        if poisonSprite == nil {
            poisonSprite = SKSpriteNode(texture: GemColor.vals[GemColor.Green.rawValue].effectFramesTextures![0])
            addChild(poisonSprite!)
            poisonSprite!.position.y += 50
            poisonSprite!.zPosition = 90
            poisonSprite!.setScale(1.5)
            
            let poisonAnimAction = SKAction.animateWithTextures(GemColor.vals[GemColor.Green.rawValue].effectFramesTextures!, timePerFrame: 0.05)
            poisonSprite!.runAction(SKAction.repeatActionForever(poisonAnimAction))
        }
        
        // If any weaker poison ticks are already present, overwrite them
        for var tick = 0; tick < poisonTicks.count; tick++ {
            if poisonTicks[tick] < dmg {
                poisonTicks[tick] = dmg
            }
        }
        // If fewer poison ticks than applied are present, apply remaining ticks
        if numTicks > poisonTicks.count {
            for var tick = poisonTicks.count; tick < numTicks; tick++ {
                poisonTicks.append(dmg)
            }
        }
    }
    
    func TickPoison() {
        let dmg = poisonTicks.first
        if dmg != nil && currHp >= 0 {
            poisonTicks.removeFirst()
            ProjectDamage(dmg!, armorBypass: 1.0)
            TakeDamage(dmg!, armorBypass: 1.0)
            
            if poisonTicks.count > 0 {
                let waitAction = SKAction.waitForDuration(poisonTickInterval)
                let tickAction = SKAction.runBlock {
                    self.TickPoison()
                }
                runAction(SKAction.sequence([waitAction, tickAction]))
            }
            else {
                if self.poisonSprite != nil {
                    self.poisonSprite!.removeFromParent()
                    self.poisonSprite = nil
                }
            }
        }
    }
}