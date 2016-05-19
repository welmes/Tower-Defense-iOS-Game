//
//  EnemyWave.swift
//  Tower Defense Game
//
//  Created by William Elmes on 4/15/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

class EnemyWave: SKNode {
    var enemyType: EnemyType
    var enemyHp: Double
    var enemyArmor: Double
    var enemySpeed: Double
    var enemyScale: CGFloat
    var enemyBounty: Double
    var enemyScore: Double
    
    var incomingEnemies: Int
    var spawnInterval: Double
    var wavePeriod: Double
    
    var parentRound: LevelRound?
    var enemies = [EnemyUnit]()
    
    init(type: EnemyType, hp: Double, armor: Double, speed: Double, scale: Double, bounty: Double, score: Double, numberEnemies: Int, interval: Double, period: Double) {
        enemyType = type
        enemyHp = hp
        enemyArmor = armor
        enemySpeed = speed
        enemyScale = CGFloat(scale)
        enemyBounty = bounty
        enemyScore = score
        
        incomingEnemies = numberEnemies
        spawnInterval = interval
        wavePeriod = period
        
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func StartSpawning(startCell: MapCellNode) {
        let spawnTimer = SKAction.waitForDuration(spawnInterval)
        let spawnNext = SKAction.runBlock {
            self.SpawnEnemy(startCell)
        }
        runAction(SKAction.sequence([spawnTimer, spawnNext]))
    }
    
    private func SpawnEnemy(startCell: MapCellNode) {
        // If there is an enemy waiting to be spawned, spawn next enemy
        if incomingEnemies > 0 {
            let enemy = EnemyUnit(wave: self, enemyType: enemyType, hp: enemyHp, armor: enemyArmor, speed: enemySpeed, scale: enemyScale, bounty: enemyBounty, score: enemyScore)
            enemies.append(enemy)
            addChild(enemy)
        
            enemy.BeginPathing(startCell)
            incomingEnemies--
        }
        
        game!.SetWaveLabel()
        
        // If there are still enemies waiting to be spawned, start timer to spawn next enemy
        if incomingEnemies > 0 {
            let spawnTimer = SKAction.waitForDuration(spawnInterval)
            let spawnNext = SKAction.runBlock {
                self.SpawnEnemy(startCell)
            }
            let spawnSequence = SKAction.sequence([spawnTimer, spawnNext])
            runAction(spawnSequence)
        }
    }
    
    func GetEnemiesInRange(tower: TowerUnit) -> [EnemyUnit] {
        var enemiesInRange = [EnemyUnit]()
        for enemy in enemies {
            if enemy.projectedHp > 0 && tower.TargetIsInRange(enemy) {
                enemiesInRange.append(enemy)
            }
        }
        
        //print("\(enemies.count) enemies in wave - \(enemiesInRange.count) enemies in range in wave...")
        
        return enemiesInRange
    }
    
    func EnemyKilled(enemy: EnemyUnit) {
        let index = enemies.indexOf(enemy)
        if index != nil {
            enemies.removeAtIndex(index!)
        }
        game!.SetWaveLabel()
    }
}