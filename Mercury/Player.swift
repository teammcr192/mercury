//
//  Player.swift
//  Mercury
//
//  Created by Richard Teammco on 11/13/16.
//  Copyright © 2016 Richard Teammco. All rights reserved.
//
//  The Player object is controlled by the user by touching and dragging. It can fire bullets and perform other specialized attacks against enemies. If the Player's life depleats to 0, it's game over!

import SpriteKit

class Player: InteractiveGameObject {
  
  // How often the player fires a bullet (in seconds) when firing.
  private let fireBulletIntervalSeconds: Double
  
  // The bullet fire timer. If active, this will trigger bullet fires every fireBulletIntervalSeconds time interval.
  private var fireBulletTimer: Timer?
  
  init(xPos: Int, yPos: Int, size: Int) {
    self.fireBulletIntervalSeconds = 0.1
    super.init()
    
    self.nodeName = "player"
    self.movementSpeed = 4.0
    
    // TODO: temporary color and shape
    self.gameSceneNode = SKShapeNode.init(rectOf: CGSize.init(width: size, height: size))
    if let gameSceneNode = self.gameSceneNode {
      gameSceneNode.position = CGPoint(x: xPos, y: yPos)
      gameSceneNode.fillColor = SKColor.blue
    }
  }
  
  // Moves the player towards the user's touch position if the player is currently touched down.
  func movePlayerIfTouched(towards: CGPoint, elapsedTime: TimeInterval) {
    if self.isTouched {
      let playerPosition = self.getSceneNode().position
      var dx = towards.x - playerPosition.x
      var dy = towards.y - playerPosition.y
      dx = dx * CGFloat(self.movementSpeed) * CGFloat(elapsedTime)
      dy = dy * CGFloat(self.movementSpeed) * CGFloat(elapsedTime)
      self.moveBy(dx: dx, dy: dy)
    }
  }
  
  // Start firing bullets at the firing rate (fireBulletIntervalSeconds). This will continue to fire bullets at each of the intervals until stopFireBulletTimer() is called.
  // TODO: we may want to move this method into the GameObject super class.
  private func startFireBulletTimer() {
    let fireBulletTimer = Timer.scheduledTimer(timeInterval: self.fireBulletIntervalSeconds, target: self, selector: #selector(self.fireBullet), userInfo: nil, repeats: true)
    self.fireBulletTimer = fireBulletTimer
    fireBullet()  // Also fire at time 0 before the timer ticks.
  }
  
  // Stops firing bullets by invalidating the fireBulletTimer.
  // TODO: we may want to move this method into the GameObject super class.
  private func stopFireBulletTimer() {
    if let fireBulletTimer = self.fireBulletTimer {
      fireBulletTimer.invalidate()
    }
  }
  
  // Called by the fireBulletTimer at each fire interval to shoot a bullet.
  // TODO: we may want to move this method into the GameObject super class.
  @objc func fireBullet() {
    print("Fired")
  }
  
  override func touchDown() {
    super.touchDown()
    if let gameSceneNode = self.gameSceneNode {
      gameSceneNode.fillColor = SKColor.red
    }
    startFireBulletTimer()
  }
  
  override func touchUp() {
    super.touchUp()
    if let gameSceneNode = self.gameSceneNode {
      gameSceneNode.fillColor = SKColor.blue
    }
    stopFireBulletTimer()
  }
  
}
