//
//  LevelRound.swift
//  Tower Defense Game
//
//  Created by William Elmes on 4/18/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

class LevelRound: SKNode {
    var activeWaves = [EnemyWave]()
    var incomingWaves = [EnemyWave]()
    
    init(waves: [EnemyWave]) {
        incomingWaves.appendContentsOf(waves)
        
        super.init()
        
        for wave in incomingWaves {
            addChild(wave)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func GetEnemiesInRange(tower: TowerUnit) -> [EnemyUnit] {
        var enemiesInRange = [EnemyUnit]()
        for wave in activeWaves {
            enemiesInRange.appendContentsOf(wave.GetEnemiesInRange(tower))
            
            //print("\(enemiesInRange.count) enemies in range in active round...")
        }
        
        return enemiesInRange
    }
    
    func StartNextWave() {
        if game!.map.startCell == nil {
            print("ERROR: StartNextWave() - startCell has not yet been set")
            return
        }
        
        let wave = incomingWaves.first
        
        if wave == nil {
            return
        }
        incomingWaves.removeFirst()
        wave!.StartSpawning(game!.map.startCell!)
        activeWaves.append(wave!)
        game!.SetWaveLabel()
        game!.StartWaveTimer(wave!.wavePeriod)
    }
}