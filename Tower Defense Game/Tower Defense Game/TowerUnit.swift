//
//  TowerUnit.swift
//  Tower Defense Game
//
//  Created by William Elmes on 3/31/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

let gemOffset: CGFloat = cellHeight * 0.25
let targetSearchInterval: Double = 0.0625

class TowerUnit: SKNode {
    var gem: GemItem?
    var isAttacking = false
    var isSearching = false
    var targetEnemy: EnemyUnit?
    let unitSprite: SKSpriteNode
    
    override init() {
        unitSprite = SKSpriteNode(imageNamed: "Tower")
        unitSprite.zPosition = 100
        
        super.init()
        
        addChild(unitSprite)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func SearchForTarget() {
        // Make sure tower can attack and there are targets to attack
        if gem == nil || game!.rounds.first == nil {
            StopTargetSearch()
            return
        }
        
        if isSearching || isAttacking {
            return
        }
        
        isSearching = true
        
        // Attempt to acquire a target and begin attacking
        if !isAttacking {
            let enemiesInRange = game!.rounds.first!.GetEnemiesInRange(self)
            if enemiesInRange.count > 0 {
                targetEnemy = gem!.AcquireTarget(enemiesInRange)
                isSearching = false
                isAttacking = true
                targetEnemy!.GetAttacked(self)
                
                print("Tower acquired target...")
                
                FireWeapon()
                return
            }
        }
        // If no target was available, loop target search
        if !isAttacking {
            let waitAction = SKAction.waitForDuration(targetSearchInterval)
            let searchBlockAction = SKAction.runBlock {
                self.isSearching = false
                self.SearchForTarget()
            }
            let sequenceAction = SKAction.sequence([waitAction, searchBlockAction])
            runAction(sequenceAction, withKey: "targetSearch")
        }
        
        
        
//        // If active round is complete, stop searching for targets
//        if game!.activeRound == nil || gem == nil {
//            StopTargetSearch()
//            return
//        }
//        
//        // Search for a valid enemy target
//        if !isAttacking {
//            let enemiesInRange = game!.activeRound!.GetEnemiesInRange(self)
//            AcquireTarget(enemiesInRange)
//        }
//        // Repeat search if a target was not found
//        if !isAttacking {
//            let waitAction = SKAction.waitForDuration(targetSearchInterval)
//            let searchBlockAction = SKAction.runBlock {
//                self.SearchForTarget()
//            }
//            let sequenceAction = SKAction.sequence([waitAction, searchBlockAction])
//            runAction(sequenceAction, withKey: "targetSearch")
//        }
    }
    
    func FireWeapon() {
        if targetEnemy == nil || isAttacking == false {
            //removeActionForKey("fireWeaponLoop")
            SearchForTarget()
            return
        }
        
        if gem != nil {
            if !TargetIsInRange(targetEnemy!) {
                targetEnemy!.OutrangedAttacker(self)
                targetEnemy = nil
                isAttacking = false
                
                print("Target outranged tower...")
                
                SearchForTarget()
                return
            }
            else {
                targetEnemy!.ProjectDamage(gem!.GetDamage(), armorBypass: 0)
                gem!.LaunchAttack(self)
                
                var waitAction: SKAction
                if gem!.charges == nil || gem!.charges > 0 {
                   waitAction = SKAction.waitForDuration(gem!.GetAttackPeriod())
                }
                else {
                    waitAction = SKAction.waitForDuration(gem!.GetAttackPeriod() * rechargePenalty)
                }
                let fireWeaponAction = SKAction.runBlock {
                    self.FireWeapon()
                }
                runAction(SKAction.sequence([waitAction, fireWeaponAction]), withKey: "fireWeaponLoop")
            }
        }
        
//        if targetEnemy == nil || isAttacking == false {
//            SearchForTarget()
//        }
//        
//        if targetEnemy != nil || gem != nil {
//            if !TargetIsInRange(targetEnemy!) {
//                targetEnemy?.OutrangedAttacker(self)
//                targetEnemy = nil
//                isAttacking = false
//                SearchForTarget()
//                
//                print("Target outranged tower...")
//            }
//            else {
//                ProjectDamageTarget()
//                gem!.LaunchAttack(self)
//                
//                let waitAction = SKAction.waitForDuration(gem!.GetAttackPeriod())
//                let fireWeaponAction = SKAction.runBlock {
//                    self.FireWeapon()
//                }
//                runAction(SKAction.sequence([waitAction, fireWeaponAction]), withKey: "fireWeaponLoop")
//            }
//        }
    }
    
    func StopTargetSearch() {
        removeActionForKey("targetSearch")
        isSearching = false
    }
    
//    func AcquireTarget(enemies: [EnemyUnit]) {
//        if enemies.count == 0 || gem == nil {
//            return
//        }
//        
//        targetEnemy = gem!.AcquireTarget(enemies)
//        print("Tower acquired target...")
//        BeginAttacking()
//    }
    
//    func BeginAttacking() {
//        if gem == nil || gem!.GetAttackPeriod() == 0 || gem!.GetDamage() == 0 || gem!.GetRange() == 0 {
//            return
//        }
//        
//        isAttacking = true
//        targetEnemy?.GetAttacked(self)
//        FireWeapon()
//    }
    
//    func DamageTarget() {
//        if gem == nil {
//            return
//        }
//        
//        targetEnemy?.TakeDamage(gem!.GetDamage(), armorBypass: 0)
//    }
    
//    func ProjectDamageTarget() {
//        if gem == nil {
//            return
//        }
//        
//        targetEnemy?.ProjectDamage(gem!.GetDamage(), armorBypass: 0)
//    }
    
    func TargetIsInRange(target: EnemyUnit) -> Bool {
        if gem == nil {
            return false
        }
        
        let enemyPosition = convertPoint(target.position, fromNode: target.parent!)
        let deltaX = position.x - enemyPosition.x
        let deltaY = position.y - enemyPosition.y
        let targetDistance = deltaX * deltaX + deltaY * deltaY
        let attackRange = gem!.GetRange() * cellWidth
        
        //print("range(\(attackRange)) dist(\(sqrt(targetDistance))")
        //print("\(sqrt(targetDistance)) target distance, \(attackRange) attack range")
        
        if targetDistance > attackRange * attackRange {
            return false
        }
        return true
    }
    
    func ClearTarget() {
        targetEnemy = nil
        isAttacking = false
        //removeActionForKey("fireWeaponLoop")
        
        print("Tower dropped target...")
        
        //SearchForTarget()
    }
    
    func TargetKilled(enemy: EnemyUnit) {
        if enemy == targetEnemy {
            ClearTarget()
        }
    }
}