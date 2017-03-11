//
//  GameScene.swift
//  Mercury
//
//  Created by Richard Teammco on 11/12/16.
//  Copyright © 2016 Richard Teammco. All rights reserved.
//
//  The GameScene controlls all of the sprites, animations, and physics in the app. It also handles user touch inputs.

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
  
  // GameState that keeps track of all of the game's state variables.
  private var gameState: GameState?
  
  //------------------------------------------------------------------------------
  // Scene initialization.
  //------------------------------------------------------------------------------
  
  // Called whenever the scene is presented into the view.
  override func didMove(to view: SKView) {
    // Set the size of the world based on the scene's size.
    self.worldSize = min(self.size.width, self.size.height)
    
    self.enemies = [Enemy]()
    self.friendlyProjectiles = [GameObject]()
    self.gameState = GameState()
    
    initializePhysics()
    initializeScene()
  }
  
  // Set the contact delegate and disable gravity.
  private func initializePhysics() {
    self.physicsWorld.contactDelegate = ContactDelegate()
    self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
  }
  
  // Initialize the current level scene by setting up all GameObjects and events.
  func initializeScene() {
    // Override function as needed.
    let testLevel = TestLevel()
    setCurrentLevel(to: testLevel)
  }
  
  // Add the player object to the scene (optional).
  func createPlayer(atPosition position: CGPoint) {
    let player = Player(position: getScaledPosition(position), gameState: getGameState())
    addGameObject(player)
    self.player = player
  }
  
  //------------------------------------------------------------------------------
  // General level methods.
  //------------------------------------------------------------------------------
  
  // Adds the given GameObject type to the scene by appending its node. The object is automatically scaled according to the screen size.
  func addGameObject(_ gameObject: GameObject) {
    if let worldSize = self.worldSize {
      let sceneNode = gameObject.createGameSceneNode(scale: worldSize)
      sceneNode.name = gameObject.nodeName
      addChild(sceneNode)
    }
  }
  
  // Displays text on the screen that disappears after a few seconds.
  func displayTextOnScreen(message: NSString) {
    // TODO: actually display this text, not just print it.
    print("In displayTextOnScreen. Message is:", message)
  }
  
  // Returns a scaled version of the given normalized position. Position (0, 0) is in the center. If the X coordinate is -1, that's the left-most side of the screen; +1 is the right-most side. Since the screen is taller than it is wide, +/-1 in the Y axis is not going to be completely at the bottom or top.
  func getScaledPosition(_ normalizedPosition: CGPoint) -> CGPoint {
    if let worldSize = self.worldSize {
      let halfWorldSize = worldSize / 2.0
      return CGPoint(x: halfWorldSize * normalizedPosition.x, y: halfWorldSize * normalizedPosition.y)
    }
    return normalizedPosition
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
  
  // Returns the GameState for this GameScene. This GameState contains all game state variables and should be updated by any and all objects that need to set their variables to the global game state for Events and other objects to reference.
  func getGameState() -> GameState {
    if let gameState = self.gameState {
      return gameState
    }
    return GameState()
  }
  
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
  
  //------------------------------------------------------------------------------
  // Touch event methods.
  //------------------------------------------------------------------------------
  
  func touchDown(atPoint pos: CGPoint) {
    let node: SKNode = atPoint(pos)
    self.gameState?.inform("screen touchDown", value: ScreenTouchInfo(pos, node))
    self.lastTouchPosition = pos
  }
  
  func touchMoved(toPoint pos: CGPoint) {
    let node: SKNode = atPoint(pos)
    self.gameState?.inform("screen touchMoved", value: ScreenTouchInfo(pos, node))
    self.lastTouchPosition = pos
  }
  
  func touchUp(atPoint pos: CGPoint) {
    let node: SKNode = atPoint(pos)
    self.gameState?.inform("screen touchUp", value: ScreenTouchInfo(pos, node))
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


// Extend the GameScene class to implement the EventProtocol, giving it the when() method and allowing events to be used.
extension GameScene: EventCaller {
  
  func when(_ event: Event) -> Event {
    event.setCaller(to: self)
    event.start()
    return event
  }
  
}
