//
//  GameScene.swift
//  Mercury
//
//  Created by Richard Teammco on 11/12/16.
//  Copyright © 2016 Richard Teammco. All rights reserved.
//
//  The GameScene controlls all of the sprites, animations, and physics in the app. It also handles user touch inputs. The Level instance that's currently being run handles all of the game logic, and works closely with the GameScene for detecting sprite interactions.

import SpriteKit
import GameplayKit

class GameScene: SKScene {
  
  // Game units.
  var player: Player?
  var enemies: [Enemy]?
  var friendlyProjectiles: [GameObject]?
  
  // The size of the world used for scaling all displayed scene nodes.
  var worldSize: CGFloat?
  
  // User touch interaction variables.
  private var lastTouchPosition: CGPoint?
  
  // Animation variables.
  private var lastFrameTime: TimeInterval?
  
  // Animation display objects.
  private var linePathNode: SKShapeNode?
  
  //------------------------------------------------------------------------------
  // Scene initialization.
  //------------------------------------------------------------------------------
  
  // Called whenever the scene is presented into the view.
  override func didMove(to view: SKView) {
    // Set the size of the world to the screen's current size.
//    self.size = view.bounds.size
//    self.scaleMode = SKSceneScaleMode.aspectFill
    self.worldSize = min(self.size.width, self.size.height)
    //self.worldSize = (self.size.width + self.size.height) / 4.0
    
    self.enemies = [Enemy]()
    self.friendlyProjectiles = [GameObject]()
    initializePhysics()
    initializeScene()
  }
  
  // Set the contact delegate and disable gravity.
  private func initializePhysics() {
    self.physicsWorld.contactDelegate = ContactDelegate()
    self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
  }
  
  // Add the player object to the scene (optional).
  func createPlayer(atPosition position: CGPoint) {
    // TEMPORARY
    let playerSize = CGSize(width: 0.15, height: 0.15)
    let playerNode = SKShapeNode(rectOf: getScaledSize(playerSize))
    playerNode.position = getScaledPosition(position)
    print(playerNode.position)
    playerNode.fillColor = SKColor.blue
    self.addChild(playerNode)
  }
  
  // Initialize the current level scene by setting up all GameObjects and events.
  func initializeScene() {
    createPlayer(atPosition: CGPoint(x: 0.0, y: 0.0))
    // Override function as needed.
    
    let testLevel = TestLevel()
    setCurrentLevel(to: testLevel)
  }
  
  //------------------------------------------------------------------------------
  // General level methods.
  //------------------------------------------------------------------------------
  
  // Sets the current GameScene to the object defined in the given GameScene file. This GameScene will be presented to the view.
  func setCurrentLevel(to nextLevel: GameScene) {
    if let view = self.view {
      // Copy the current GameScene's properties.
      nextLevel.size = self.size
      nextLevel.scaleMode = self.scaleMode
      nextLevel.anchorPoint = self.anchorPoint
      view.presentScene(nextLevel)
    }
  }
  
  func getScaledSize(_ normalizedSize: CGSize) -> CGSize {
    if let worldSize = self.worldSize {
      return CGSize(width: worldSize * normalizedSize.width, height: worldSize * normalizedSize.height)
    }
    return normalizedSize
  }
  
  func getScaledPosition(_ normalizedPosition: CGPoint) -> CGPoint {
    if let worldSize = self.worldSize {
      return CGPoint(x: worldSize * normalizedPosition.x, y: worldSize * normalizedPosition.y)
    }
    return normalizedPosition
  }
  
  // Adds the given GameObject type to the scene by appending its node.
  // In addition, scales the movement speed and Sprite node size of the GameObject by the world size to account for the size of the device screen. If scaleSpeed is set to false, the speed will not be scaled. This is useful for certain nodes such as the Player which are moved by user interaction, meaning the speed is already inherently scaled to the size/resolution of the screen.
  func addGameObject(gameObject: GameObject, scaleSpeed: Bool = true) {
    if let worldSize = self.worldSize {  // TODO?
      if scaleSpeed {
        gameObject.scaleMovementSpeed(worldSize)
      }
    }
    self.addChild(gameObject.getSceneNode())
  }
  
  // Returns true if the given object is within screen bounds.
  func isGameObjectWithinScreenBounds(gameObject: GameObject) -> Bool {
    // TODO
    return true
  }
  
  // Returns the previous position on the screen that a user's touch occured.
  // The previous location is the one before the latest touch action. If no touch was previously recorded, returns (0, 0) which is the center of the screen.
  func getPreviousTouchPosition() -> CGPoint {
    if let previousTouchPosition = self.lastTouchPosition {
      return previousTouchPosition
    } else {
      return CGPoint(x: 0, y: 0)
    }
  }
  
  //------------------------------------------------------------------------------
  // Touch event methods.
  //------------------------------------------------------------------------------
  
  func touchDown(atPoint pos: CGPoint) {
    // TODO
    self.lastTouchPosition = pos
  }
  
  func touchMoved(toPoint pos: CGPoint) {
    // TODO
    self.lastTouchPosition = pos
  }
  
  func touchUp(atPoint pos: CGPoint) {
    // TODO
  }
  
  //------------------------------------------------------------------------------
  // Animation update methods.
  //------------------------------------------------------------------------------
  
  // This method measures the elapsed time since the last frame and updates the current game level.
  // Called before each frame is rendered with the current time.
  override func update(_ currentTime: TimeInterval) {
    // TODO
    //if let lastFrameTime = self.lastFrameTime {
    //  let elapsedTime = currentTime - lastFrameTime
    //}
    self.lastFrameTime = currentTime
  }
  
  //------------------------------------------------------------------------------
  // SKScene multitouch handlers.
  //------------------------------------------------------------------------------
  
  // Called when user starts a touch action.
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchDown(atPoint: t.location(in: self)) }
  }
  
  // Called when user moves (drags) during a touch action.
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
  }
  
  // Called when user finishes a touch action.
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchUp(atPoint: t.location(in: self)) }
  }
  
  // Called when a touch action is interrupted or otherwise cancelled.
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches { self.touchUp(atPoint: t.location(in: self)) }
  }
  
}
