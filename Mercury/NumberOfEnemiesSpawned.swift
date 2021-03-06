//
//  NumberOfEnemiesSpawned.swift
//  Mercury
//
//  Created by Richard Teammco on 1/31/17.
//  Copyright © 2017 Richard Teammco. All rights reserved.
//

class NumberOfEnemiesSpawned: EventStopper {
  
  let numEnemiesToSpawn: Int
  var numEnemiesAtStart: Int?
  
  init(equals count: Int) {
    self.numEnemiesToSpawn = count
  }
  
  // When the parent Event starts, the initial number of enemies that was spawned is known.
  override func startTrackingStopCriteria() {
    self.numEnemiesAtStart = GameScene.gameState.getInt(forKey: .numSpawnedEnemies, defaultValue: 0)
  }
  
  // We use GameState's tracking directly in case there's a phase reset. Phase reset will cause the number of enemies spawned counter to reset to what it was before the phase began.
  override func isSatisfied() -> Bool {
    let maxNumEnemies = getRequiredNumberOfEnemies()
    let count = GameScene.gameState.getInt(forKey: .numSpawnedEnemies)
    return count >= maxNumEnemies
  }
  
  // Returns the total number of enemies that have to have been spawned in the GameScene for this EventStopper to be satisfied.
  private func getRequiredNumberOfEnemies() -> Int {
    if let numEnemiesAtStart = self.numEnemiesAtStart {
      return numEnemiesAtStart + self.numEnemiesToSpawn
    } else {
      return self.numEnemiesToSpawn
    }
  }
  
}
