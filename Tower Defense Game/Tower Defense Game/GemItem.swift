//
//  GemItem.swift
//  Tower Defense Game
//
//  Created by William Elmes on 3/14/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

let projectileMoveAmt: CGFloat = 50.0
let slowAmt: Double = 0.5
let slowDur: Double = 2.0
let maxCharges: Int = 3
let rechargePenalty: Double = 2.0

struct GemColorAttributes {
    let colorName: String
    let typeName: String
    let sizeScale: CGFloat
    
    let range: CGFloat
    let attackPeriod: Double
    let damage: [Double]
    
    let attackEffect: ((TowerUnit) -> Void)
    let targetPrioritization: (([EnemyUnit]) -> EnemyUnit)
    
    var launchFramesTextures: [SKTexture]
    var projectileFramesTextures: [SKTexture]
    var impactFramesTextures: [SKTexture]
    var effectFramesTextures: [SKTexture]?
}

enum GemColor: Int {
    case Red = 0
    case Yellow
    case Green
    case Blue
    
    static let vals = [
        GemColorAttributes(colorName: "Red", typeName: "Ruby", sizeScale: 1.5, range: 1.5, attackPeriod: 1.0, damage: [150, 195, 240, 285, 330], attackEffect: RedAttackLaunch, targetPrioritization: StandardTargetPrioritization, launchFramesTextures: LoadLaunchAnimation("Red"), projectileFramesTextures: LoadProjectileAnimation("Red"), impactFramesTextures: LoadImpactAnimation("Red"), effectFramesTextures: LoadEffectAnimation("Red")),
        GemColorAttributes(colorName: "Yellow", typeName: "Topaz", sizeScale: 1.5, range: 4.0, attackPeriod: 1.0, damage: [200, 260, 320, 380, 440], attackEffect: YellowAttackLaunch, targetPrioritization: StandardTargetPrioritization, launchFramesTextures: LoadLaunchAnimation("Yellow"), projectileFramesTextures: LoadProjectileAnimation("Yellow"), impactFramesTextures: LoadImpactAnimation("Yellow"), effectFramesTextures: LoadEffectAnimation("Yellow")),
        GemColorAttributes(colorName: "Green", typeName: "Emerald", sizeScale: 1.5, range: 2.5, attackPeriod: 2.5, damage: [100, 130, 160, 190, 220], attackEffect: GreenAttackLaunch, targetPrioritization: PoisonedTargetPrioritization, launchFramesTextures: LoadLaunchAnimation("Green"), projectileFramesTextures: LoadProjectileAnimation("Green"), impactFramesTextures: LoadImpactAnimation("Green"), effectFramesTextures: LoadEffectAnimation("Green")),
        GemColorAttributes(colorName: "Blue", typeName: "Aquamarine", sizeScale: 1.5, range: 1.5, attackPeriod: 1.5, damage: [100, 130, 160, 190, 220], attackEffect: BlueAttackLaunch, targetPrioritization: SlowedTargetPrioritization, launchFramesTextures: LoadLaunchAnimation("Blue"), projectileFramesTextures: LoadProjectileAnimation("Blue"), impactFramesTextures: LoadImpactAnimation("Blue"), effectFramesTextures: LoadEffectAnimation("Blue"))
    ]
    
    static func randomColor() -> GemColor {
        let rand = arc4random_uniform(UInt32(vals.count))
        return GemColor(rawValue: Int(rand))!
    }
}

enum GemRank: Int {
    case Sliver = 0
    case Fragment
    case Chunk
    case Cluster
    case Core
    
    static let vals = ["Sliver", "Fragment", "Chunk", "Cluster", "Core"]
    
    static func randomRank() -> GemRank {
        let rand = arc4random_uniform(UInt32(vals.count))
        return GemRank(rawValue: Int(rand))!
    }
}

class GemItem: SKNode {
    var color: GemColor?
    var rank: GemRank?
    var charges: Int?
    var itemSprite: SKSpriteNode?
    
    var launchSprites = [SKSpriteNode]()
    var projectileSprites = [SKSpriteNode]()
    
    init(gemColor: GemColor, gemRank: GemRank) {
        color = gemColor
        rank = gemRank
        itemSprite = SKSpriteNode(imageNamed: "\(GemColor.vals[color!.rawValue].colorName)\(rank!.rawValue)")
        itemSprite?.userInteractionEnabled = false
        
        super.init()
        
        if color == .Yellow {
            charges = maxCharges
        }
        addChild(itemSprite!)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func SetColor(gemColor: GemColor) {
        color = gemColor
        SetTexture()
    }
    
    func SetRank(gemRank: GemRank) {
        rank = gemRank
        SetTexture()
    }
    
    func RandomizeColor() {
        SetColor(GemColor.randomColor())
        SetTexture()
    }
    
    func RandomizeRank(upgradeLevel: Int) {
        SetRank(GemRank.randomRank())
        SetTexture()
    }
    
    func GetDamage() -> Double {
        if color == nil || rank == nil {
            return 0
        }
        
        return GemColor.vals[color!.rawValue].damage[rank!.rawValue]
    }
    
    func GetRange() -> CGFloat {
        if color == nil {
            return 0
        }
        
        return GemColor.vals[color!.rawValue].range
    }
    
    func GetAttackPeriod() -> Double {
        if color == nil {
            return 0
        }
        
        return GemColor.vals[color!.rawValue].attackPeriod
    }
    
    func AcquireTarget(enemies: [EnemyUnit]) -> EnemyUnit {
        return GemColor.vals[color!.rawValue].targetPrioritization(enemies)
    }
    
    func LaunchAttack(tower: TowerUnit) {
        // TO DO: Visual effect of attack,
        //  Tell target to update itself on impact
        GemColor.vals[color!.rawValue].attackEffect(tower)
    }
    
    private func SetTexture() {
        if color != nil && rank != nil {
            itemSprite!.texture = SKTexture(imageNamed: "\(GemColor.vals[color!.rawValue].colorName)\(rank!.rawValue)")
        }
    }
}

func RedAttackLaunch(tower: TowerUnit) {
    if tower.gem == nil || tower.gem!.color == nil || tower.gem!.rank == nil {
        return
    }
    
    //print("Launching red attack...")
    
    // Attack impact
    let impactWaitAction = SKAction.waitForDuration(0.2)
    let impactAction = SKAction.runBlock {
        let enemiesInRange = game!.rounds.first!.GetEnemiesInRange(tower)
        for enemy in enemiesInRange {
            enemy.TakeDamage(tower.gem!.GetDamage(), armorBypass: 0)
            
            let impactSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].impactFramesTextures[0])
            enemy.impactSprites.append(impactSprite)
            enemy.addChild(impactSprite)
            impactSprite.position.y += 30
            impactSprite.zPosition = 400
            impactSprite.setScale(2.0)
            
            let impactAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].impactFramesTextures, timePerFrame: 0.02)
            let impactAnimEndAction = SKAction.runBlock {
                let index = enemy.impactSprites.indexOf(impactSprite)
                if index != nil {
                    enemy.impactSprites.removeAtIndex(index!)
                }
                impactSprite.removeFromParent()
            }
            impactSprite.runAction(SKAction.sequence([impactAnimAction, impactAnimEndAction]))
        }
    }
    tower.runAction(SKAction.sequence([impactWaitAction, impactAction]))
    
    // Attack launch
    let launchSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].launchFramesTextures[0])
    tower.gem!.launchSprites.append(launchSprite)
    tower.gem!.addChild(launchSprite)
    launchSprite.position.y += 25
    launchSprite.zPosition = 600
    launchSprite.setScale(2.0)
    
    let launchAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].launchFramesTextures, timePerFrame: 0.02)
    let launchAnimEndAction = SKAction.runBlock {
        let index = tower.gem!.launchSprites.indexOf(launchSprite)
        if index != nil {
            tower.gem!.launchSprites.removeAtIndex(index!)
        }
        launchSprite.removeFromParent()
    }
    launchSprite.runAction(SKAction.sequence([launchAnimAction, launchAnimEndAction]))
    
    // Attack projectile
    let projectileSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].projectileFramesTextures[0])
    tower.gem!.projectileSprites.append(projectileSprite)
    tower.gem!.addChild(projectileSprite)
    projectileSprite.position.y -= 25
    projectileSprite.zPosition = 500
    projectileSprite.setScale(3.5 * tower.gem!.GetRange())
    
    let projectileAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].projectileFramesTextures, timePerFrame: 0.05)
    let projectileAnimEndAction = SKAction.runBlock {
        let index = tower.gem!.projectileSprites.indexOf(projectileSprite)
        if index != nil {
            tower.gem!.projectileSprites.removeAtIndex(index!)
        }
        projectileSprite.removeFromParent()
    }
    projectileSprite.runAction(SKAction.sequence([projectileAnimAction, projectileAnimEndAction]))
}

func BlueAttackLaunch(tower: TowerUnit) {
    // TO DO:
    //  tower.FireWeapon()
    //  apply slow to target
    //  clear target
    
    //print("Launching blue attack...")
    
    // Attack projectile
    let projectileSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].projectileFramesTextures[0])
    tower.gem!.projectileSprites.append(projectileSprite)
    tower.gem!.addChild(projectileSprite)
    //projectileSprite.position.y += 10
    projectileSprite.zPosition = 300
    projectileSprite.setScale(2)
    
    let projectileAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].projectileFramesTextures, timePerFrame: 0.05)
    projectileSprite.runAction(SKAction.repeatActionForever(projectileAnimAction))
    
    MoveProjectile(tower, target: tower.targetEnemy!, projectile: projectileSprite, flightPeriod: 0.05, impactEffect: BlueAttackImpact)
    
    // Attack launch
    let launchSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].launchFramesTextures[0])
    tower.gem!.launchSprites.append(launchSprite)
    tower.gem!.addChild(launchSprite)
    launchSprite.position.y += 25
    launchSprite.zPosition = 500
    launchSprite.setScale(1.5)
    
    let launchAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].launchFramesTextures, timePerFrame: 0.02)
    let launchAnimEndAction = SKAction.runBlock {
        let index = tower.gem!.launchSprites.indexOf(launchSprite)
        if index != nil {
            tower.gem!.launchSprites.removeAtIndex(index!)
        }
        launchSprite.removeFromParent()
    }
    launchSprite.runAction(SKAction.sequence([launchAnimAction, launchAnimEndAction]))
    
    tower.ClearTarget()
}

func BlueAttackImpact(tower: TowerUnit, target: EnemyUnit!, projectile: SKSpriteNode!){
    //print("Blue projectile impacted!")
    
    target.ApplySlow(slowAmt, duration: slowDur)
    target.TakeDamage(tower.gem!.GetDamage(), armorBypass: 0)
    
    let impactSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].impactFramesTextures[0])
    target.impactSprites.append(impactSprite)
    target.addChild(impactSprite)
    impactSprite.position.y += 30
    impactSprite.zPosition = 400
    impactSprite.setScale(2.0)
    
    let impactAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].impactFramesTextures, timePerFrame: 0.04)
    let impactAnimEndAction = SKAction.runBlock {
        let index = target.impactSprites.indexOf(impactSprite)
        if index != nil {
            target.impactSprites.removeAtIndex(index!)
        }
        impactSprite.removeFromParent()
    }
    impactSprite.runAction(SKAction.sequence([impactAnimAction, impactAnimEndAction]))
}

func GreenAttackLaunch(tower: TowerUnit) {
    // TO DO:
    //  tower.FireWeapon()
    //  apply poison to target
    //  clear target
    
    //print("Launching green attack...")
    
    // Attack projectile
    let projectileSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].projectileFramesTextures[0])
    tower.gem!.projectileSprites.append(projectileSprite)
    tower.gem!.addChild(projectileSprite)
    //projectileSprite.position.y += 10
    projectileSprite.zPosition = 300
    projectileSprite.setScale(2)
    
    let projectileAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].projectileFramesTextures, timePerFrame: 0.4)
    projectileSprite.runAction(SKAction.repeatActionForever(projectileAnimAction))
    
    MoveProjectile(tower, target: tower.targetEnemy!, projectile: projectileSprite, flightPeriod: 0.08, impactEffect: GreenAttackImpact)
    
    // Attack launch
    let launchSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].launchFramesTextures[0])
    tower.gem!.launchSprites.append(launchSprite)
    tower.gem!.addChild(launchSprite)
    launchSprite.position.y += 25
    launchSprite.zPosition = 500
    launchSprite.setScale(1.5)
    
    let launchAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].launchFramesTextures, timePerFrame: 0.02)
    let launchAnimEndAction = SKAction.runBlock {
        let index = tower.gem!.launchSprites.indexOf(launchSprite)
        if index != nil {
            tower.gem!.launchSprites.removeAtIndex(index!)
        }
        launchSprite.removeFromParent()
    }
    launchSprite.runAction(SKAction.sequence([launchAnimAction, launchAnimEndAction]))
    
    tower.ClearTarget()
}

func GreenAttackImpact(tower: TowerUnit, target: EnemyUnit!, projectile: SKSpriteNode!){
    //print("Green projectile impacted!")
    
    target.ApplyPoison(tower.gem!.GetDamage() / 2.5, numTicks: 5)
    target.TakeDamage(tower.gem!.GetDamage(), armorBypass: 0)
    
    let impactSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].impactFramesTextures[0])
    target.impactSprites.append(impactSprite)
    target.addChild(impactSprite)
    impactSprite.position.y += 30
    impactSprite.zPosition = 400
    impactSprite.setScale(1.5)
    
    let impactAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].impactFramesTextures, timePerFrame: 0.04)
    let impactAnimEndAction = SKAction.runBlock {
        let index = target.impactSprites.indexOf(impactSprite)
        if index != nil {
            target.impactSprites.removeAtIndex(index!)
        }
        impactSprite.removeFromParent()
    }
    impactSprite.runAction(SKAction.sequence([impactAnimAction, impactAnimEndAction]))
}

func YellowAttackLaunch(tower: TowerUnit) {
    //print("Launching yellow attack with \(tower.gem!.charges!) charges...")
    
    // Start the recharge loop only if at max charges before attack
    if tower.gem!.charges == maxCharges {
        let rechargeWaitAction = SKAction.waitForDuration(tower.gem!.GetAttackPeriod() * rechargePenalty)
        let rechargeAction = SKAction.runBlock {
            tower.gem!.charges = tower.gem!.charges! + 1
            if tower.gem!.charges! == maxCharges {
                tower.gem!.removeActionForKey("rechargeLoop")
            }
        }
        tower.gem!.runAction(SKAction.repeatActionForever(SKAction.sequence([rechargeWaitAction, rechargeAction])), withKey: "rechargeLoop")
    }
    
    // Remove a charge
    tower.gem!.charges = tower.gem!.charges! - 1
    
    // Attack projectile
    let projectileSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].projectileFramesTextures[0])
    tower.gem!.projectileSprites.append(projectileSprite)
    tower.gem!.addChild(projectileSprite)
    //projectileSprite.position.y += 10
    projectileSprite.zPosition = 300
    projectileSprite.setScale(2)
    
    let projectileAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].projectileFramesTextures, timePerFrame: 0.05)
    projectileSprite.runAction(SKAction.repeatActionForever(projectileAnimAction))
    
    MoveProjectile(tower, target: tower.targetEnemy!, projectile: projectileSprite, flightPeriod: 0.05, impactEffect: YellowAttackImpact)
    
    // Attack launch
    let launchSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].launchFramesTextures[0])
    tower.gem!.launchSprites.append(launchSprite)
    tower.gem!.addChild(launchSprite)
    launchSprite.position.y += 25
    launchSprite.zPosition = 500
    launchSprite.setScale(1.5)
    
    let launchAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].launchFramesTextures, timePerFrame: 0.02)
    let launchAnimEndAction = SKAction.runBlock {
        let index = tower.gem!.launchSprites.indexOf(launchSprite)
        if index != nil {
            tower.gem!.launchSprites.removeAtIndex(index!)
        }
        launchSprite.removeFromParent()
    }
    launchSprite.runAction(SKAction.sequence([launchAnimAction, launchAnimEndAction]))
}

func YellowAttackImpact(tower: TowerUnit, target: EnemyUnit!, projectile: SKSpriteNode!){
    //print("Yellow projectile impacted!")
    
    target.TakeDamage(tower.gem!.GetDamage(), armorBypass: 0)
    
    let impactSprite = SKSpriteNode(texture: GemColor.vals[tower.gem!.color!.rawValue].impactFramesTextures[0])
    target.impactSprites.append(impactSprite)
    target.addChild(impactSprite)
    impactSprite.position.y += 30
    impactSprite.zPosition = 400
    impactSprite.setScale(2.0)
    
    let impactAnimAction = SKAction.animateWithTextures(GemColor.vals[tower.gem!.color!.rawValue].impactFramesTextures, timePerFrame: 0.04)
    let impactAnimEndAction = SKAction.runBlock {
        let index = target.impactSprites.indexOf(impactSprite)
        if index != nil {
            target.impactSprites.removeAtIndex(index!)
        }
        impactSprite.removeFromParent()
    }
    impactSprite.runAction(SKAction.sequence([impactAnimAction, impactAnimEndAction]))
}

func MoveProjectile(tower: TowerUnit, target: EnemyUnit!, projectile: SKSpriteNode!, flightPeriod: Double, impactEffect: (TowerUnit, EnemyUnit!, SKSpriteNode!) -> Void) {
//    print("tower: (\(tower.position.x), \(tower.position.y))")
//    print("projectile: (\(projectile.position.x), \(projectile.position.y))")
//    print("target: (\(tower.targetEnemy!.position.x), \(tower.targetEnemy!.position.y))")
//    print("target.converted: (\(projectile.convertPoint(tower.targetEnemy!.position, fromNode: tower.targetEnemy!.parent!).x), \(projectile.convertPoint(tower.targetEnemy!.position, fromNode: tower.targetEnemy!.parent!).y))")
    
    let targetPos = projectile.parent!.convertPoint(target.position, fromNode: target.parent!)
    let dx = targetPos.x - projectile.position.x
    let dy = targetPos.y - projectile.position.y
    let distSq = dx * dx + dy * dy
    if distSq < projectileMoveAmt * projectileMoveAmt {
        let moveOffset = CGVectorMake(dx, dy)
        
        //print("Moving projectile by (\(moveOffset.dx), \(moveOffset.dy))")
        
        let moveAction = SKAction.moveBy(moveOffset, duration: flightPeriod)
        let impactAction = SKAction.runBlock {
            // Attack impact
            impactEffect(tower, target, projectile)
            
            let index = tower.gem!.projectileSprites.indexOf(projectile)
            if index != nil {
                tower.gem!.projectileSprites.removeAtIndex(index!)
            }
            projectile.removeFromParent()
            //print("Projectile impacted!")
        }
        projectile.runAction(SKAction.sequence([moveAction, impactAction]))
        return
    }
    
    var moveOffset = CGVectorMake(dx, dy)
    moveOffset.dx = (moveOffset.dx / sqrt(distSq)) * projectileMoveAmt
    moveOffset.dy = (moveOffset.dy / sqrt(distSq)) * projectileMoveAmt
    
    //print("Moving projectile by (\(moveOffset.dx), \(moveOffset.dy))")
    
    let angle = atan2(dx, dy) - CGFloat(M_PI) / 2
    let rotateAction = SKAction.rotateToAngle(angle, duration: 0)
    let moveAction = SKAction.moveBy(moveOffset, duration: flightPeriod)
    let moveLoopAction = SKAction.runBlock {
        MoveProjectile(tower, target: target, projectile: projectile, flightPeriod: flightPeriod, impactEffect: impactEffect)
    }
    projectile.runAction(SKAction.sequence([rotateAction, moveAction, moveLoopAction]))
}

// Priority:
//  Greatest distance
func StandardTargetPrioritization(var enemies: [EnemyUnit]) -> EnemyUnit {
    var target = enemies.first!
    enemies.removeFirst()
    for enemy in enemies {
        if enemy.projectedHp > 0 && enemy.travelDist > target.travelDist {
            target = enemy
        }
    }
    
    return target
}

// Priority:
//  Un-slowed, greatest distance
//  Slowed, weakest slow, greatest distance
func SlowedTargetPrioritization(enemies: [EnemyUnit]) -> EnemyUnit {
    var target: EnemyUnit?
    
    // Get highest priority non-slowed target
    for enemy in enemies {
        if enemy.projectedHp > 0 && enemy.slows.count == 0 && (target == nil || enemy.travelDist > target!.travelDist) {
            target = enemy
        }
        
//        if enemy.slows.count > 0 && (priorityTarget == nil || enemy.travelDist > priorityTarget!.travelDist) {
//            priorityTarget = enemy
//        }
//        else if priorityTarget == nil && (standardTarget == nil || enemy.travelDist > standardTarget!.travelDist) {
//            standardTarget = enemy
//        }
    }
    
    // If no non-slowed target, get highest priority slowed target
    if target == nil {
        for enemy in enemies {
            if enemy.projectedHp > 0 && (target == nil || enemy.travelDist > target!.travelDist) {
                target = enemy
            }
        }
    }
    
    return target!
    
    
    
//    var priorityTargets = [EnemyUnit]()
//    priorityTargets.append(enemies.first!)
//    enemies.removeFirst()
//    
//    for enemy in enemies {
//        if enemy.slows.count < priorityTargets.first!.slows.count {
//            priorityTargets.removeAll()
//            priorityTargets.append(enemy)
//        }
//        else if enemy.slows.count == priorityTargets.first!.slows.count {
//            priorityTargets.append(enemy)
//        }
//    }
//    
//    if priorityTargets.first!.slows.count != 0 {
//        var slowedTargets = [EnemyUnit]()
//        slowedTargets.appendContentsOf(priorityTargets)
//        priorityTargets.removeAll()
//        priorityTargets.append(slowedTargets.first!)
//        slowedTargets.removeFirst()
//        
//        for enemy in slowedTargets {
//            if enemy.slows.first! < priorityTargets.first!.slows.first! {
//                priorityTargets.removeAll()
//                priorityTargets.append(enemy)
//            }
//            else if enemy.slows.first! == priorityTargets.first!.slows.first! {
//                priorityTargets.append(enemy)
//            }
//        }
//    }
//    
//    var target = priorityTargets.first!
//    priorityTargets.removeFirst()
//    for enemy in priorityTargets {
//        if enemy.travelDist > target.travelDist {
//            target = enemy
//        }
//    }
//    
//    return target
}

// Priority:
//  Un-poisoned, greatest distance
//  Poisoned, least damage, fewest ticks remaining, greatest distance
func PoisonedTargetPrioritization(enemies: [EnemyUnit]) -> EnemyUnit {
    var target: EnemyUnit?
    
    // Get highest priority non-poisoned target
    for enemy in enemies {
        if enemy.projectedHp > 0 && enemy.poisonTicks.count == 0 && (target == nil || enemy.travelDist > target!.travelDist) {
            target = enemy
        }
    }
    
    // If no non-poisoned target, get highest priority poisoned target
    if target == nil {
        for enemy in enemies {
            if enemy.projectedHp > 0 && (target == nil || enemy.travelDist > target!.travelDist) {
                target = enemy
            }
        }
    }
    
    return target!
    
    
    
    
//    var priorityTargets = [EnemyUnit]()
//    
//    // Prioritize un-poisoned enemies
//    for enemy in enemies {
//        if enemy.poisonTicks.count == 0 {
//            priorityTargets.append(enemy)
//        }
//    }
//    
//    // There are no un-poisoned enemies
//    if priorityTargets.count == 0 {
//        // Get all poisoned targets with the highest poison tick damage
//        var poisonedTargets = [EnemyUnit]()
//        poisonedTargets.append(enemies.first!)
//        enemies.removeFirst()
//        for enemy in enemies {
//            if enemy.poisonTicks.first! > poisonedTargets.first!.poisonTicks.first! {
//                poisonedTargets.removeAll()
//                poisonedTargets.append(enemy)
//            }
//            else if enemy.poisonTicks.first! == poisonedTargets.first!.poisonTicks.first! {
//                poisonedTargets.append(enemy)
//            }
//        }
//        
//        // Get all poisoned targets with the highest poison tick damage and fewest ticks remaining
//        priorityTargets.append(poisonedTargets.first!)
//        poisonedTargets.removeFirst()
//        for enemy in poisonedTargets {
//            if enemy.poisonTicks.count < priorityTargets.first!.poisonTicks.count {
//                priorityTargets.removeAll()
//                priorityTargets.append(enemy)
//            }
//            else if enemy.poisonTicks.count == priorityTargets.first!.poisonTicks.count {
//                priorityTargets.append(enemy)
//            }
//        }
//    }
//    
//    // Prioritize enemies based on greatest distance travelled
//    var target = priorityTargets.first!
//    priorityTargets.removeFirst()
//    for enemy in priorityTargets {
//        if enemy.travelDist > target.travelDist {
//            target = enemy
//        }
//    }
//    
//    return target
}

func LoadLaunchAnimation(color: String) -> [SKTexture] {
    //print("Loading launch animation...")
    
    var frameTextures = [SKTexture]()
    var numFrames: Int
    
    switch(color) {
    case "Red":
        numFrames = 28
    case "Yellow":
        numFrames = 32
    case "Green":
        numFrames = 32
    case "Blue":
        numFrames = 32
    default:
        return frameTextures
    }
    
    //print("numFrames: \(numFrames)")
    let textureAtlas = SKTextureAtlas(named: "Attacks")
    //print("...")
    for var frame = 0; frame < numFrames; frame++ {
        //print("frame: \(frame) color: \(color)")
        let textureName = "\(color)Launch\(String(format: "%02d", frame))"
        //print("Loading frame[\(frame)]: \(textureName)")
        frameTextures.append(textureAtlas.textureNamed(textureName))
    }
    
    return frameTextures
}

func LoadProjectileAnimation(color: String) -> [SKTexture] {
    //print("Loading projectile animation...")
    
    var frameTextures = [SKTexture]()
    var numFrames: Int
    
    switch(color) {
    case "Red":
        numFrames = 14
    case "Yellow":
        numFrames = 8
    case "Green":
        numFrames = 20
    case "Blue":
        numFrames = 16
    default:
        return frameTextures
    }
    
    let textureAtlas = SKTextureAtlas(named: "Attacks")
    for var frame = 0; frame < numFrames; frame++ {
        let textureName = "\(color)Projectile\(String(format: "%02d", frame))"
        //print("Loading: \(textureName)")
        frameTextures.append(textureAtlas.textureNamed(textureName))
    }
    
    return frameTextures
}

func LoadImpactAnimation(color: String) -> [SKTexture] {
    //print("Loading impact animation...")
    
    var frameTextures = [SKTexture]()
    var numFrames: Int
    
    switch(color) {
    case "Red":
        numFrames = 20
    case "Yellow":
        numFrames = 16
    case "Green":
        numFrames = 21
    case "Blue":
        numFrames = 20
    default:
        return frameTextures
    }
    
    let textureAtlas = SKTextureAtlas(named: "Attacks")
    for var frame = 0; frame < numFrames; frame++ {
        let textureName = "\(color)Impact\(String(format: "%02d", frame))"
        //print("Loading: \(textureName)")
        frameTextures.append(textureAtlas.textureNamed(textureName))
    }
    
    return frameTextures
}

func LoadEffectAnimation(color: String) -> [SKTexture]? {
    var numFrames: Int
    
    switch(color) {
    case "Red":
        return nil
    case "Yellow":
        return nil
    case "Green":
        numFrames = 20
    case "Blue":
        numFrames = 16
    default:
        return nil
    }
    
    var frameTextures = [SKTexture]()
    let textureAtlas = SKTextureAtlas(named: "Attacks")
    for var frame = 0; frame < numFrames; frame++ {
        let textureName = "\(color)Effect\(String(format: "%02d", frame))"
        frameTextures.append(textureAtlas.textureNamed(textureName))
    }
    
    return frameTextures
}