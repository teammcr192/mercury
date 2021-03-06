//
//  Enemy.swift
//  Mercury
//
//  Created by Richard Teammco on 12/1/16.
//  Copyright © 2016 Richard Teammco. All rights reserved.
//
//  An abstract Enemy object that should be extended to include specific enemies. This defines standard actions that most enemy units will take, such as random-interval shooting.

import SpriteKit

class Enemy: PhysicsEnabledGameObject, ArmedWithProjectiles {
  
  // The bullet fire timer key. If active, this will trigger bullet fires every fireBulletIntervalSeconds time interval.
  static let fireBulletTimerKey = "enemy bullet timer"
  
  override init(position: CGPoint) {
    super.init(position: position)
    self.nodeName = "enemy"
    initializeHitPoints(GameScene.gameState.getCGFloat(forKey: .enemyHealthBase))
    
    // Customize physics properties:
    self.physicsMass = 1.0
    self.physicsRestitution = 0.5
    self.physicsFriction = 0.5
    self.physicsAllowsRotation = false
    
    // Physics collision properties: Enemies can collide with the player.
    setCollisionCategory(PhysicsCollisionBitMask.enemy)
    addCollisionTestCategory(PhysicsCollisionBitMask.friendly)
    // TODO: they should probably be able to collide with the environment as well?
  }
  
  // TODO: temporary color and shape.
  override func createGameSceneNode(scale: CGFloat) -> SKNode {
    let size = GameConfiguration.smallObjectSize * scale
    let node = SKShapeNode.init(rectOf: CGSize.init(width: size, height: size))
    node.position = getPosition()
    node.fillColor = SKColor.cyan
    self.gameSceneNode = node
    self.initializePhysics()
    return node
  }
  
  // When an enemy dies, inform the global GameState of the specific event.
  override func destroyObject() {
    super.destroyObject()
    ParticleSystems.runExplosionEffect(on: self)
    GameScene.gameState.inform(.enemyDied, value: self)
  }
  
  //------------------------------------------------------------------------------
  // Methods for the ArmedWithProjectiles protocol.
  //------------------------------------------------------------------------------
  
  // The enemy will begin shooting when its initial motion finishes.
  override func notifyMotionEnded() {
    super.notifyMotionEnded()
    startFireBulletTimer()
  }
  
  // Start firing bullets at the firing rate (fireBulletIntervalSeconds). This will continue to fire bullets at each of the intervals until stopFireBulletTimer() is called.
  // TODO: we may want to move this method into the GameObject super class.
  func startFireBulletTimer() {
    let bulletFireIntervalSeconds = GameScene.gameState.getTimeInterval(forKey: .enemyBulletFireInterval)
    startLoopedTimer(withKey: Enemy.fireBulletTimerKey, every: bulletFireIntervalSeconds, withCallback: fireBullet, fireImmediately: true)
  }
  
  // Stops firing bullets by invalidating the fireBulletTimer.
  func stopFireBulletTimer() {
    stopLoopedTimer(withKey: Enemy.fireBulletTimerKey)
  }
  
  // Called by the fireBulletTimer at each fire interval to shoot a bullet.
  func fireBullet() {
    let enemyPosition = getPosition()
    let bullet = Bullet(position: CGPoint(x: enemyPosition.x, y: enemyPosition.y), speed: GameConfiguration.enemyBulletSpeed, damage: GameScene.gameState.getCGFloat(forKey: .enemyBulletDamage))
    bullet.setColor(to: GameConfiguration.enemyColor)
    bullet.addCollisionTestCategory(PhysicsCollisionBitMask.friendly)
    bullet.addCollisionTestCategory(PhysicsCollisionBitMask.environment)
    
    // Set the direction of the bullet based on the player's current position.
    let playerPosition = Util.getPlayerWorldPosition()
    var bulletDirection = Util.getDirectionVector(from: enemyPosition, to: playerPosition)
    bulletDirection.dx += Util.getUniformRandomValue(between: -0.1, and: 0.1)
    bulletDirection.dy += Util.getUniformRandomValue(between: -0.1, and: 0.1)
    bullet.setMovementDirection(to: bulletDirection)
    
    GameScene.gameState.inform(.spawnEnemyBullet, value: bullet)
  }
  
}
