//
//  LevelParser.swift
//  Tower Defense Game
//
//  Created by William Elmes on 5/15/16.
//  Copyright © 2016 William Elmes. All rights reserved.
//

import Foundation
import SpriteKit

func ParseLevel(fileName: String) -> Bool {
    print("Loading level: \"\(fileName)\"...")
    
    var pathMap: [[Bool]]?
    var buildMap: [[Bool]]?
    var startCell: (x: Int, y: Int)?
    var endCell: (x: Int, y: Int)?
    var tileset: Tileset?
    var startHp: Int?
    var startEnergy: Double?
    var rounds = [LevelRound]()
    
    
    // Load the contents of the file into a string
    let fileLocation = NSBundle.mainBundle().pathForResource(fileName, ofType: "txt")!
    let fileContents: String
    do {
        fileContents = try String(contentsOfFile: fileLocation)
    }
    catch {
        fileContents = ""
    }
    
    // File failed to load
    if fileContents == "" {
        print("ERROR: LoadLevel(fileName:\"\(fileName)\") - Unable to load file")
        return false
    }
    
    // Break up the lines of the file contents into an array of strings
    let lineArr = fileContents.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
    for var l = lineArr.startIndex; l < lineArr.endIndex; l++ {
        if lineArr[l] == "" {
            continue
        }
        
        let wordArr = lineArr[l].componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        wordloop: for var w = wordArr.startIndex; w < wordArr.endIndex; w++ {
            let word = wordArr[w].lowercaseString
            switch word {
            case "":
                break
                
            case "pathmap":
                let result = ParsePathMap(lineArr, pmIndex: ++l)
                if result == nil {
                    return false
                }
                
                pathMap = result!.pathMap
                buildMap = result!.buildMap
                startCell = result!.startCell
                endCell = result!.endCell
                l = result!.lineIndex
                
                print("StartCell: (\(startCell!.x), \(startCell!.y)), EndCell: (\(endCell!.x), \(endCell!.y))")
                
                break wordloop
                
            case "tileset":
                let result = ParseTileset(wordArr, wIndex: ++w)
                if result == nil {
                    return false
                }
                tileset = result
                
                print("tileset: \(tileset!.rawValue)")
                
                break wordloop
                
            case "startattributes":
                let result = ParseStartAttributes(lineArr, startIndex: ++l)
                if result == nil {
                    return false
                }
                startHp = result!.startHp
                startEnergy = result!.startEnergy
                l = result!.lineIndex
                
                print("startEnergy: \(startEnergy!), startHp: \(startHp!)")
                
                break wordloop
                
            case "rounds":
                let result = ParseRounds(lineArr, rIndex: l)
                if result == nil {
                    return false
                }
                rounds.appendContentsOf(result!.rounds)
                l = result!.lineIndex
                
                print("Rounds: [\(rounds.count)]")
                
                break wordloop
                
            default:
                print("ERROR: LoadLevel(fileName:\"\(fileName)\") - Unrecognized primary token: \"\(word)\"")
                return false
            }
        }
    }
    
    if pathMap == nil || buildMap == nil || startCell == nil || endCell == nil {
        print("ERROR: LoadLevel(fileName:\"\(fileName)\") - Path map not found")
        return false
    }
    if tileset == nil {
        print("ERROR: LoadLevel(fileName:\"\(fileName)\") - Tileset not found")
        return false
    }
    if startHp == nil || startEnergy == nil {
        print("ERROR: LoadLevel(fileName:\"\(fileName)\") - Start attributes not found")
        return false
    }
    if rounds.count == 0 {
        print("ERROR: LoadLevel(fileName:\"\(fileName)\") - Rounds not found")
        return false
    }
    
    if !game!.map.Load(tileset!, pathMap: pathMap!, buildMap: buildMap!, start: startCell!, end: endCell!) {
        print("ERROR: LoadLevel(fileName:\"\(fileName)\") - Path map does not contain a contiguous path")
        return false
    }
    game!.rounds.appendContentsOf(rounds)
    game!.SetPlayerHp(startHp!)
    game!.SetPlayerEnergy(startEnergy!)
    for round in rounds {
        game!.addChild(round)
    }
    
    print("Level loaded!")
    return true
}

// Pathmap and buildmap - [row][col]
func ParsePathMap(lineArr: [String], pmIndex: Int) -> (lineIndex: Int, pathMap: [[Bool]], buildMap: [[Bool]], startCell: (x: Int, y: Int)?, endCell: (x: Int, y: Int)?)? {
    print("Parsing path map...")
    
    var lineIndex = pmIndex
    var pathMapCellsParsed = 0
    var pathMap = [[Bool]](count: mapHeight, repeatedValue:[Bool](count: mapWidth, repeatedValue: true))
    var buildMap = [[Bool]](count: mapHeight, repeatedValue:[Bool](count: mapWidth, repeatedValue: true))
    var startCell: (x: Int, y: Int)?
    var endCell: (x: Int, y: Int)?
    
    var row = 0
    // Loop through lines until all values are found or end of file is reached
    for var l = pmIndex; (pathMapCellsParsed < mapWidth * mapHeight || startCell == nil || endCell == nil) && l < lineArr.endIndex; l++ {
        // Get line in lowercase, trimmed of white space, and all space characters in between removed
        let line = lineArr[l].lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()).stringByReplacingOccurrencesOfString(" ", withString: "")
        // Skip empty lines
        if line == "" {
            continue
        }
        
        // Validate size of the line
        if line.characters.count != mapWidth {
            print("ERROR: ParsePathMap(line:\(pmIndex + 1)) - Pathmap row contains invalid number of characters: \"\(line)\"")
            return nil
        }
        
        // Loop through the characters of the line
        for var c = 0; c < line.characters.count; c++ {
            //print("Checking pathmap: (\(l - pmIndex), \(c))")
            
            switch line[line.startIndex.advancedBy(c)] {
                // Pathable only cell
            case "p":
                pathMap[mapHeight - 1 - row][c] = true
                buildMap[mapHeight - 1 - row][c] = false
                pathMapCellsParsed++
                
                // Open cell: pathable and buildable
            case "o":
                pathMap[mapHeight - 1 - row][c] = true
                buildMap[mapHeight - 1 - row][c] = true
                pathMapCellsParsed++
                
                // Buildable only cell
            case "b":
                pathMap[mapHeight - 1 - row][c] = false
                buildMap[mapHeight - 1 - row][c] = true
                pathMapCellsParsed++
                // Closed cell: not pathable and not buildable
            case "c":
                pathMap[mapHeight - 1 - row][c] = false
                buildMap[mapHeight - 1 - row][c] = false
                pathMapCellsParsed++
                
                // Start cell: required and must be unique, pathable and not buildable
            case "s":
                if startCell != nil {
                    print("ERROR: ParsePathMap(line:\(l + 1)) - Found multiple start cells: (\(row), \(c))")
                    return nil
                }
                startCell = (c, mapHeight - 1 - row)
                pathMap[mapHeight - 1 - row][c] = true
                buildMap[mapHeight - 1 - row][c] = false
                pathMapCellsParsed++
                
                // End cell: required must be unique, pathable and not buildable
            case "e":
                if endCell != nil {
                    print("ERROR: ParsePathMap(line:\(l + 1)) - Found multiple end cells: (\(row), \(c))")
                    return nil
                }
                endCell = (c, mapHeight - 1 - row)
                pathMap[mapHeight - 1 - row][c] = true
                buildMap[mapHeight - 1 - row][c] = false
                pathMapCellsParsed++
                
                // Unrecognized path map token
            default:
                print("ERROR: ParsePathMap(line:\(l + 1)) - Unrecognized pathmap character: \"\(line[line.startIndex.advancedBy(c)])\"")
                return nil
            }
        }
        
        row++
        lineIndex = l
    }
    
    if pathMapCellsParsed < mapWidth * mapHeight || startCell == nil || endCell == nil {
        print("ERROR: ParsePathMap(line:\(pmIndex + 1)) - Path map is incomplete")
        return nil
    }
    
    print("Path map parsed!")
    return (lineIndex, pathMap, buildMap, startCell, endCell)
}

func ParseTileset(wordArr: [String], var wIndex: Int) -> Tileset? {
    print("Parsing tileset...")
    
    var tilesetName = ""
    // Parse the words on the line of the tileset token, ignoring empty words created by white space
    while tilesetName == "" && wIndex < wordArr.endIndex {
        tilesetName = wordArr[wIndex].lowercaseString
        wIndex++
    }
    
    switch tilesetName {
        // Sand tileset
    case "sand":
        print("Tileset parsed!")
        return .Sand
        
        // Unrecognized tileset token
    default:
        print("ERROR: ParseTileset(tilesetName:\"\(tilesetName)\") - Unrecognized tileset name")
        return nil
    }
}

func ParseStartAttributes(lineArr: [String], startIndex: Int) -> (lineIndex: Int, startHp: Int?, startEnergy: Double?)? {
    print("Parsing start attributes...")
    
    var startHp: Int?
    var startEnergy: Double?
    var lineIndex = startIndex
    
    // Loop through lines until all values are found or end of file is reached
    for var l = startIndex; (startHp == nil || startEnergy == nil) && l < lineArr.endIndex; l++ {
        // Get the next line and format it
        let line = lineArr[l].lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        // Skip empty lines
        if line == "" {
            continue
        }
        
        // Break up the line into an array of words
        let wordArr = line.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        // Loop through the array of words
        wordloop: for var w = wordArr.startIndex; w < wordArr.endIndex; w++ {
            let word = wordArr[w]
            switch word {
                // Skip empty words created by white space
            case "":
                continue wordloop
                
                // Parse start hp
            case "hp":
                if startHp != nil {
                    print("ERROR: ParseStartAttributes(line:\(l + 1)) - Found multiple values for start hp")
                    return nil
                }
                
                w++
                // Parse each word in the line after the hp token
                while startHp == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as an int
                    let i = Int(wordArr[w])
                    if i == nil {
                        print("ERROR: ParseStartAttribute(line:\(l + 1)) - Invalid value for start hp: \(wordArr[w])")
                        return nil
                    }
                    // Set start hp and record the line number
                    startHp = i
                    lineIndex = l
                    w++
                }
                // Ignore remaining words in the line (comments)
                break wordloop
                
                // Parse start energy
            case "energy":
                if startEnergy != nil {
                    print("ERROR: ParseStartAttributes(line:\(l + 1)) - Found multiple values for start energy")
                    return nil
                }
                
                w++
                // Parse each word in the line after the energy token
                while startEnergy == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as a double
                    let d = Double(wordArr[w])
                    if d == nil {
                        print("ERROR: ParseStartAttribute(line:\(l + 1)) - Invalid value for start energy: \(wordArr[w])")
                        return nil
                    }
                    // Set start hp and record the line number
                    startEnergy = d
                    lineIndex = l
                    w++
                }
                // Ignore remaining words in the line (comments)
                break wordloop
                
                // Unrecognized start attribute token
            default:
                print("ERROR: ParseStartAttributes(line:\(l + 1)) - Unrecognized start attribute token: \"\(word)\"")
                return nil
            }
        }
    }
    
    // Verify that all start attributes have been set
    if startHp == nil || startEnergy == nil {
        print("ERROR: ParseStartAttributes(line:\(startIndex + 1)) - Start attributes did not contain both hp and energy")
        return nil
    }
    
    // Return the start attributes and the line index after the start attributes
    print("Start attributes parsed!")
    return (lineIndex, startHp, startEnergy)
}

func ParseRounds(lineArr: [String], rIndex: Int) -> (lineIndex: Int, rounds: [LevelRound])? {
    print("Parsing rounds...")
    
    var lineIndex = rIndex
    var roundsParsed = 0
    var rounds = [LevelRound]()
    
    // Parse the number of rounds
    var numRounds: Int?
    let wordArr = lineArr[rIndex].componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    // Parse the words on the line of the rounds token, ignoring empty words created by white space
    for var w = wordArr.startIndex; numRounds == nil && w < wordArr.endIndex; w++ {
        let word = wordArr[w].lowercaseString
        
        // Ignore empty words created by white space and the rounds token
        if word == "" || word == "rounds" {
            continue
        }
        
        // Validate the number of rounds as an int
        numRounds = Int(word)
        if numRounds == nil {
            print("ERROR: ParseRounds(line:\(rIndex + 1)) - Invalid number of rounds: \"\(word)\"")
            return nil
        }
        break
    }
    
    // Verify the number of rounds was parsed
    if numRounds == nil {
        print("ERROR: ParseRounds(line:\(rIndex + 1)) - Number of rounds not found")
        return nil
    }
    
    //print(" Parsed number rounds: \(numRounds!)")
    
    // Loop through lines until all rounds are parsed or end of file is reached
    for var l = rIndex + 1; roundsParsed < numRounds! && l < lineArr.endIndex; {
        // Get line in lowercase, trimmed of white space
        let line = lineArr[l].lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        // Skip empty lines
        if line == "" {
            continue
        }
        
        // Break up the line into an array of words
        var wordArr = line.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        // Loop through the array of words
        wordloop: for var w = wordArr.startIndex; w < wordArr.endIndex; w++ {
            let word = wordArr[w]
            switch word {
                // Skip empty words created by white space
            case "":
                continue wordloop
                
                // Parse the round token
            case "round":
                //print("     Parsed \"round\"")
                
                var numWaves: Int?
                
                w++
                var next = ParseNextWord(wordArr, wordIndex: w)
                if next == nil {
                    print("ERROR: ParseRounds(line:\(l + 1)) - Could not find \"waves\" token")
                    return nil
                }
                if next!.word != "waves" {
                    print("ERROR: ParseRounds(line:\(l + 1)) - Expected token: \"waves\", found token: \"\(next!.word)\"")
                    return nil
                }
                w = next!.wordIndex
                
                //print("     Parsed \"waves\"")
                
                next = ParseNextWord(wordArr, wordIndex: w)
                if next == nil {
                    print("ERROR: ParseRounds(line:\(l + 1)) - Could not find number of waves")
                    return nil
                }
                numWaves = Int(next!.word)
                if numWaves == nil {
                    print("ERROR: ParseRounds(line:\(l + 1)) - Invalid number of waves token: \"\(next!.word)\"")
                    return nil
                }
                
                //print("     Parsed number waves: \(numWaves!)")
                
                var waves = [EnemyWave]()
                l++
                for var waveIndex = 0; waveIndex < numWaves! && l < lineArr.endIndex; waveIndex++ {
                    let waveResult = ParseWave(lineArr, wIndex: l)
                    if waveResult == nil {
                        return nil
                    }
                    l = waveResult!.lineIndex
                    waves.append(waveResult!.wave)
                }
                
                if waves.count < numWaves! {
                    print("ERROR: ParseRounds(line:\(l + 1)) - Invalid number of waves for round; expected: \(numWaves!), found: \(waves.count)")
                    return nil
                }
                
                let round = LevelRound(waves: waves)
                rounds.append(round)
                for wave in waves {
                    wave.parentRound = round
                }
                //print("     Parsed round: \(round.incomingWaves.count)")
                
                lineIndex = l
                roundsParsed++
                break wordloop
                
                // Unrecognized round token
            default:
                print("ERROR: ParseRounds(line:\(l + 1)) - Unrecognized round token: \"\(word)\"")
                return nil
            }
        }
    }
    
    // Verify that all the rounds have been parsed
    if roundsParsed < numRounds {
        print("ERROR: ParseRounds(line:\(rIndex + 1)) - Incorrect number of rounds parsed")
        return nil
    }
    
    print("Rounds parsed!")
    return (lineIndex, rounds)
}

func ParseWave(lineArr: [String], wIndex: Int) -> (lineIndex: Int, wave: EnemyWave)? {
    var lineIndex = wIndex
    var wave: EnemyWave?
    
    var enemyType: EnemyType?
    var enemyHp: Double?
    var enemyArmor: Double?
    var enemySpeed: Double?
    var enemyScale: Double?
    var enemyBounty: Double?
    var enemyScore: Double?
    var numEnemies: Int?
    var spawnInterval: Double?
    var wavePeriod: Double?
    
    // Parse the wave token, indicating the beginning of a wave
    var l: Int
    wavelineloop: for l = wIndex; l < lineArr.endIndex; l++ {
        let line = lineArr[l].lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        if line == "" {
            continue
        }
        
        let wordArr = line.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        wavewordloop: for var w = wordArr.startIndex; w < wordArr.endIndex; w++ {
            let word = wordArr[w]
            switch word {
            case "":
                continue wavewordloop
                
            case "wave":
                //print("         Parsed \"wave\"")
                break wavelineloop
                
            default:
                print("ERROR: ParseWave(line:\(l + 1)) - Expected token: \"wave\", found token: \"\(word)\"")
                return nil
            }
        }
    }
    
    // Loop through lines until all values are found or end of file is reached
    for l++; (enemyType == nil || enemyHp == nil || enemyArmor == nil || enemySpeed == nil || enemyScale == nil || enemyBounty == nil || enemyScore == nil || numEnemies == nil || spawnInterval == nil || wavePeriod == nil) && l < lineArr.endIndex; l++ {
        // Get the next line and format it
        let line = lineArr[l].lowercaseString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        // Skip empty lines
        if line == "" {
            continue
        }
        
        // Break up the line into an array of words
        let wordArr = line.componentsSeparatedByCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        // Loop through the array of words
        wordloop: for var w = wordArr.startIndex; w < wordArr.endIndex; w++ {
            let word = wordArr[w]
            
            switch word {
                // Skip empty words created by white space
            case "":
                continue wordloop
                
                // Parse enemy type
            case "enemytype":
                if enemyType != nil {
                    print("ERROR: ParseWave(line:\(l + 1)) - Found multiple values enemytype")
                    return nil
                }
                
                w++
                // Parse each word in the line after the enemytype token
                typeloop: while enemyType == nil && w < wordArr.endIndex {
                    let word = wordArr[w]
                    
                    // Validate the word as an enemy type
                    switch word {
                    case "":
                        w++
                        continue typeloop
                        
                    case "skeleton":
                        enemyType = EnemyType(rawValue: EnemyType.Skeleton.rawValue)
                        // Record the line number
                        lineIndex = l + 1
                        // Ignore remaining words in the line (comments)
                        break wordloop
                        
                    default:
                        print("ERROR: ParseWave(line:\(l + 1)) - Invalid enemy type token: \"\(wordArr[w])\"")
                        return nil
                    }
                }
                
                // Parse enemy hp
            case "enemyhp":
                if enemyHp != nil {
                    print("ERROR: ParseWave(line:\(l + 1)) - Found multiple values for enemyhp")
                    return nil
                }
                
                w++
                // Parse each word in the line after the enemyhp token
                while enemyHp == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as a double
                    let d = Double(wordArr[w])
                    if d == nil {
                        print("ERROR: ParseWave(line:\(l + 1)) - Invalid value for enemyhp: \(wordArr[w])")
                        return nil
                    }
                    // Set enemy hp and record the line number
                    enemyHp = d
                    lineIndex = l + 1
                    // Ignore remaining words in the line (comments)
                    break wordloop
                }
                
                // Parse enemy armor
            case "enemyarmor":
                if enemyArmor != nil {
                    print("ERROR: ParseWave(line:\(l + 1)) - Found multiple values for enemyarmor")
                    return nil
                }
                
                w++
                // Parse each word in the line after the enemyarmor token
                while enemyArmor == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as a double
                    let d = Double(wordArr[w])
                    if d == nil {
                        print("ERROR: ParseWave(line:\(l + 1)) - Invalid value for enemyarmor: \(wordArr[w])")
                        return nil
                    }
                    // Set enemy armor and record the line number
                    enemyArmor = d
                    lineIndex = l + 1
                    // Ignore remaining words in the line (comments)
                    break wordloop
                }
                
                // Parse enemy speed
            case "enemyspeed":
                if enemySpeed != nil {
                    print("ERROR: ParseWave(line:\(l + 1)) - Found multiple values for enemyspeed")
                    return nil
                }
                
                w++
                // Parse each word in the line after the enemyspeed token
                while enemySpeed == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as a double
                    let d = Double(wordArr[w])
                    if d == nil {
                        print("ERROR: ParseWave(line:\(l + 1)) - Invalid value for enemyspeed: \(wordArr[w])")
                        return nil
                    }
                    // Set enemy speed and record the line number
                    enemySpeed = d
                    lineIndex = l + 1
                    // Ignore remaining words in the line (comments)
                    break wordloop
                }
                
                // Parse enemy scale
            case "enemyscale":
                if enemyScale != nil {
                    print("ERROR: ParseWave(line:\(l + 1)) - Found multiple values for enemyscale")
                    return nil
                }
                
                w++
                // Parse each word in the line after the enemyscale token
                while enemyScale == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as a double
                    let d = Double(wordArr[w])
                    if d == nil {
                        print("ERROR: ParseWave(line:\(l + 1)) - Invalid value for enemyscale: \(wordArr[w])")
                        return nil
                    }
                    // Set enemy scale and record the line number
                    enemyScale = d
                    lineIndex = l + 1
                    // Ignore remaining words in the line (comments)
                    break wordloop
                }
                
                // Parse enemy bounty
            case "enemybounty":
                if enemyBounty != nil {
                    print("ERROR: ParseWave(line:\(l + 1)) - Found multiple values for enemybounty")
                    return nil
                }
                
                w++
                // Parse each word in the line after the enemybounty token
                while enemyBounty == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as a double
                    let d = Double(wordArr[w])
                    if d == nil {
                        print("ERROR: ParseWave(line:\(l + 1)) - Invalid value for enemybounty: \(wordArr[w])")
                        return nil
                    }
                    // Set enemy bounty and record the line number
                    enemyBounty = d
                    lineIndex = l + 1
                    // Ignore remaining words in the line (comments)
                    break wordloop
                }
                
                // Parse enemy score
            case "enemyscore":
                if enemyScore != nil {
                    print("ERROR: ParseWave(line:\(l + 1)) - Found multiple values for enemyscore")
                    return nil
                }
                
                w++
                // Parse each word in the line after the enemyscore token
                while enemyScore == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as a double
                    let d = Double(wordArr[w])
                    if d == nil {
                        print("ERROR: ParseWave(line:\(l + 1)) - Invalid value for enemyscore: \(wordArr[w])")
                        return nil
                    }
                    // Set enemy score and record the line number
                    enemyScore = d
                    lineIndex = l + 1
                    // Ignore remaining words in the line (comments)
                    break wordloop
                }
                
                // Parse number enemies
            case "numberenemies":
                if numEnemies != nil {
                    print("ERROR: ParseWave(line:\(l + 1)) - Found multiple values for numberenemies")
                    return nil
                }
                
                w++
                // Parse each word in the line after the numberenemies token
                while numEnemies == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as an int
                    let i = Int(wordArr[w])
                    if i == nil {
                        print("ERROR: ParseWave(line:\(l + 1)) - Invalid value for numberenemies: \(wordArr[w])")
                        return nil
                    }
                    // Set number enemies and record the line number
                    numEnemies = i
                    lineIndex = l + 1
                    // Ignore remaining words in the line (comments)
                    break wordloop
                }
                
                // Parse spawn interval
            case "spawninterval":
                if spawnInterval != nil {
                    print("ERROR: ParseWave(line:\(l + 1)) - Found multiple values for spawninterval")
                    return nil
                }
                
                w++
                // Parse each word in the line after the spawninterval token
                while spawnInterval == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as a double
                    let d = Double(wordArr[w])
                    if d == nil {
                        print("ERROR: ParseWave(line:\(l + 1)) - Invalid value for spawninterval: \(wordArr[w])")
                        return nil
                    }
                    // Set spawn interval and record the line number
                    spawnInterval = d
                    lineIndex = l + 1
                    // Ignore remaining words in the line (comments)
                    break wordloop
                }
                
                // Parse wave period
            case "waveperiod":
                if wavePeriod != nil {
                    print("ERROR: ParseWave(line:\(l + 1)) - Found multiple values for waveperiod")
                    return nil
                }
                
                w++
                // Parse each word in the line after the waveperiod token
                while wavePeriod == nil && w < wordArr.endIndex {
                    // Skip empty words created by white space
                    if wordArr[w] == "" {
                        w++
                        continue
                    }
                    
                    // Validate the word as a double
                    let d = Double(wordArr[w])
                    if d == nil {
                        print("ERROR: ParseWave(line:\(l + 1)) - Invalid value for waveperiod: \(wordArr[w])")
                        return nil
                    }
                    // Set wave period and record the line number
                    wavePeriod = d
                    lineIndex = l + 1
                    // Ignore remaining words in the line (comments)
                    break wordloop
                }
                
                // Unrecognized wave token
            default:
                print("ERROR: ParseWave(line:\(l + 1)) - Unrecognized wave token: \"\(word)\"")
                return nil
            }
        }
    }
    
    if enemyType == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Missing enemy type")
        return nil
    }
    if enemyHp == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Missing enemy hp")
        return nil
    }
    if enemyArmor == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Missing enemy armor")
        return nil
    }
    if enemySpeed == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Missing enemy speed")
        return nil
    }
    if enemyScale == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Missing enemy scale")
        return nil
    }
    if enemyBounty == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Missing enemy bounty")
        return nil
    }
    if enemyScore == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Missing enemy score")
        return nil
    }
    if numEnemies == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Missing number of enemies")
        return nil
    }
    if spawnInterval == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Missing spawn interval")
        return nil
    }
    if wavePeriod == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Missing wave period")
        return nil
    }
    
    wave = EnemyWave(type: enemyType!, hp: enemyHp!, armor: enemyArmor!, speed: enemySpeed!, scale: enemyScale!, bounty: enemyBounty!, score: enemyScore!, numberEnemies: numEnemies!, interval: spawnInterval!, period: wavePeriod!)
    
    if wave == nil {
        print("ERROR: ParseWave(line:\(l + 1)) - Unable to parse wave")
        return nil
    }
    
    return (lineIndex, wave!)
}

func ParseNextWord(wordArr: [String], wordIndex: Int) -> (wordIndex: Int, word: String)? {
    var index = wordIndex
    var word: String?
    
    // Parse the word array until the next word is found
    wordloop: for var w = wordIndex; w < wordArr.endIndex; w++ {
        let str = wordArr[w]
        switch str {
            // Skip empty words created by white space
        case "":
            continue wordloop
            
            // Get the next word
        default:
            word = str
            index = w + 1
            break wordloop
        }
    }
    
    if word == nil {
        return nil
    }
    
    // Return the next word and the index to its following word
    return (index, word!)
}