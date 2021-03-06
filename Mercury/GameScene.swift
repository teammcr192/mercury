//
//  GameScene.swift
//  Mercury
//
//  Created by Richard Teammco on 11/12/16.
//  Copyright © 2016 Richard Teammco. All rights reserved.
//
//  The GameScene controlls all of the sprites, animations, and physics in the app. It also handles user touch inputs. This is the main base class for all Levels to be built on top of.

import SpriteKit
import GameplayKit

class GameScene: SKScene, EventCaller, GameStateListener {
  
  // These values control the Z positions of nodes.
  static let zPositionForBackground: CGFloat = 0
  static let zPositionForObjects: CGFloat = 1
  static let zPositionForText: CGFloat = 2
  static let zPositionForGUI: CGFloat = 2
  static let zPositionForOverlayMenu: CGFloat = 3
  
  // GameState that keeps track of all of the game's state variables. If Phases are running, this will keep track of the GameState as it was *before* the phase began and it is updated whenever a phase finishes. Hence, this variable might be out-of-date for any given phase.
  static var gameState = GameState()
  
  // The scene tracks the most recent touch position.
  private var lastTouchPosition: CGPoint?
  
  // The physics system contact delegate needs to be a local variable or else it disappears.
  private var contactDelegate: ContactDelegate?
  
  // The phase sequence that will be executed when this GameScene is started.
  private var eventPhaseSequence = [EventPhase]()
  
  // The worldNode will hold everything.
  private var worldNode: SKNode?
  
  // Animation variables.
  private var lastFrameTime: TimeInterval?
  
  // This is a GameState copied before the current phase began. In the event of a phase reset, this copy will be used to reset the current GameState.
  private var previousGameState: GameState?
  
  // The current EventPhase. This is used to access the currently running phase to pause events or reset the phase.
  private var currentPhase: EventPhase?
  
  //------------------------------------------------------------------------------
  // Scene initialization.
  //------------------------------------------------------------------------------
  
  // Called whenever the scene is presented into the view.
  override func didMove(to view: SKView) {
    initializePhysics()
    initializeGameState()
    initializeScene()
  }
  
  // Set the contact delegate and disable gravity.
  private func initializePhysics() {
    self.contactDelegate = ContactDelegate()
    self.physicsWorld.contactDelegate = self.contactDelegate!
    self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
  }
  
  // Initializes values in the GameState. Eventually, this will load data from saved state values in the database.
  private func initializeGameState() {
    GameScene.gameState = GameState()
    GameScene.gameState.set(.canPauseGame, to: true)
    // TODO: These values should be adjusted from a database or some configuration file.
    let playerStatus = PlayerStatus()
    playerStatus.addPlayerExperience(15)  // TODO: This is just here for testing.
    GameScene.gameState.set(.playerStatus, to: playerStatus)
    GameScene.gameState.setCGFloat(.playerHealth, to: playerStatus.getMaxPlayerHealth())
    GameScene.gameState.setTimeInterval(.playerBulletFireInterval, to: 0.1)
    GameScene.gameState.setCGFloat(.enemyHealthBase, to: 250)
    GameScene.gameState.setCGFloat(.enemyBulletDamage, to: 5)
    GameScene.gameState.setTimeInterval(.enemyBulletFireInterval, to: 0.2)
  }
  
  // Initialize the current level scene by setting up all GameObjects and events. By default, initializes the background node and subscribes to state changes. Extend as needed.
  func initializeScene() {
    let worldSize = self.frame.height
    let worldNode = SKShapeNode(rectOf: CGSize(width: worldSize, height: worldSize))
    worldNode.fillColor = SKColor.black
    worldNode.zPosition = GameScene.zPositionForBackground
    addChild(worldNode)
    self.worldNode = worldNode
    
    subscribeToStateChanges()
  }
  
  // Creates the background animation(s). The background is added to either the world node (if available) or directly to the scene.
  //
  // TODO: Allow the background type to be specified by the user.
  func createBackground() {
    if let backgroundEmitter = SKEmitterNode(fileNamed: "FlyingStars.sks") {
      backgroundEmitter.advanceSimulationTime(10)  // So we start will full screen of stars.
      if let worldNode = self.worldNode {
        backgroundEmitter.position.y = worldNode.frame.height / 2
        backgroundEmitter.particlePositionRange = CGVector(dx: worldNode.frame.width, dy: 0)
        worldNode.addChild(backgroundEmitter)
      } else {
        backgroundEmitter.zPosition = GameScene.zPositionForBackground
        backgroundEmitter.position.y = self.frame.height / 2
        backgroundEmitter.particlePositionRange = CGVector(dx: self.frame.width, dy: 0)
        addChild(backgroundEmitter)
      }
    }
  }
  
  // Add the player object to the scene (optional).
  func createPlayer(atPosition position: CGPoint) {
    // Since the player moves within the main screen window and not the world node, we have to offset the player's position relative to the world.
    var worldPositionScaling: CGFloat = 1
    if let worldNode = self.worldNode {
      worldPositionScaling = worldNode.frame.width / self.frame.width
    }
    GameScene.gameState.setCGFloat(.playerPositionXScaling, to: worldPositionScaling)
    // Now add the player object.
    let player = Player(position: getScaledPosition(position))
    addGameObject(player, directlyToScene: true)
    when(PlayerDies()).execute(action: HandlePlayerDeath())
  }
  
  // Add the standard GUI to the scene (optional).
  func createGUI() {
    let hud = LevelHud()
    addGameObject(hud, directlyToScene: true, withZPosition: GameScene.zPositionForGUI)
  }
  
  //------------------------------------------------------------------------------
  // General level methods.
  //------------------------------------------------------------------------------
  
  // Adds the given GameObject type to the scene by appending its node. The object is automatically scaled according to the screen size.
  // Set withPhysicsScaling to true if the object is a PhysicsEnabledGameObject and its physical properties should be scaled to reflect the world size.
  func addGameObject(_ gameObject: GameObject, withPhysicsScaling: Bool = false, directlyToScene: Bool = false, withZPosition zPosition: CGFloat = GameScene.zPositionForObjects) {
    let sceneNode = gameObject.createGameSceneNode(scale: getScaleValue())
    gameObject.connectToSceneNode(sceneNode)
    sceneNode.name = gameObject.nodeName
    if withPhysicsScaling {
      gameObject.scaleMovementSpeed(getScaleValue())
      if let physicsEnabledGameObject = gameObject as? PhysicsEnabledGameObject {
        physicsEnabledGameObject.scaleMass(by: getScaleValue())
      }
    }
    sceneNode.zPosition = zPosition
    if directlyToScene {
      addChild(sceneNode)
    } else {
      self.worldNode?.addChild(sceneNode)
    }
  }
  
  // Displays text on the screen that disappears after a few seconds. Optionally set the forDuration and withFadeOutDuration values (both in seconds) to change how long the text is displayed or how long it can fade out over. These values can be 0.
  func displayTextOnScreen(message: String, forDuration textOnScreenDuration: TimeInterval = 1, withFadeOutDuration textFadeOutDuration: TimeInterval = 1) {
    let labelNode = SKLabelNode(text: message)
    labelNode.fontName = GameConfiguration.mainFont
    labelNode.fontSize = GameConfiguration.mainFontSize
    labelNode.fontColor = GameConfiguration.primaryColor
    labelNode.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
    labelNode.zPosition = GameScene.zPositionForText
    addChild(labelNode)
    
    let waitBeforeFade = SKAction.wait(forDuration: textOnScreenDuration)
    let textFadeOut = SKAction.run({
      () in labelNode.run(SKAction.fadeOut(withDuration: textFadeOutDuration))
    })
    let waitBeforeRemove = SKAction.wait(forDuration: textFadeOutDuration)
    let removeTextNode = SKAction.run({
      () in labelNode.run(SKAction.removeFromParent())
    })
    run(SKAction.sequence([waitBeforeFade, textFadeOut, waitBeforeRemove, removeTextNode]))
  }
  
  // Set the speed of the game to the given ratio. This will be applied to both the rendering and physics, effectively slowing down or speeding up time of the entire game world.
  func setGameSpeed(to relativeSpeed: CGFloat) {
    var speed = relativeSpeed
    if relativeSpeed < 0 {
      speed = 0
    }
    self.speed = speed
    self.physicsWorld.speed = speed
    // Also scale all of the particle effects. This requires looping through and manually setting each one.
    if speed > 0 {
      scaleParticleEmitterSpeed(forNode: self, withScale: speed)
      if let worldNode = self.worldNode {
        scaleParticleEmitterSpeed(forNode: worldNode, withScale: speed)
      }
    }
  }
  // Helper method for scaling particle emitter speeds. Loops over all emitter node children of the given node or scene and scales them to the given speed scale.
  private func scaleParticleEmitterSpeed(forNode node: SKNode, withScale speedScale: CGFloat) {
    for childNode in node.children {
      if let emitter = childNode as? SKEmitterNode {
        emitter.speed = speedScale
        emitter.particleBirthRate *= speedScale
        emitter.particleLifetime /= speedScale
        emitter.particleSpeed *= speedScale
        emitter.particleSpeedRange *= speedScale
        emitter.particleAlphaSpeed *= speedScale
        emitter.particleAlphaRange *= speedScale
        emitter.particleScaleSpeed *= speedScale
        emitter.particleScaleRange *= speedScale
      }
    }
  }
  
  // Pauses the game and creates a pause menu on the screen.
  private func pauseGame() {
    // View must exist and not be paused already.
    guard !self.isPaused, GameScene.gameState.getBool(forKey: .canPauseGame) else {
      return
    }
    
    // Create the pause menu. It will remove itself upon resuming the game.
    let pauseMenu = MenuNode(inFrame: self.frame, withBackgroundAlpha: 0.75)
    pauseMenu.add(label: SKLabelNode(text: "Game Paused"))
    pauseMenu.zPosition = GameScene.zPositionForOverlayMenu
    // Create a resume button. This automatically removes the pause menu when pressed.
    let resumeButton = ButtonNode(withText: "Resume")
    resumeButton.setCallback {
      pauseMenu.removeFromParent()
      GameScene.gameState.inform(.resumeGame)
    }
    pauseMenu.add(button: resumeButton)
    // Create a main menu button that will take the player to the main menu screen.
    let mainMenuButton = ButtonNode(withText: "Main Menu")
    mainMenuButton.setCallback {
      self.setCurrentLevel(to: MainMenu())
    }
    pauseMenu.add(button: mainMenuButton)
    addChild(pauseMenu)
    
    // Now actually pause the game. Need to wait 0 seconds so the pause action is executed next frame, after the pause menu was already displayed.
    let pauseGameAction = SKAction.run {
      self.isPaused = true
    }
    run(SKAction.sequence([SKAction.wait(forDuration: 0), pauseGameAction]))
  }
  
  // Call to unpause a paused game. If game is not paused, this will have no effect.
  private func resumePausedGame() {
    self.isPaused = false
  }

  // Returns a scaled version of the given normalized position. Position (0, 0) is in the center. If the X coordinate is -1, that's the left-most side of the screen; +1 is the right-most side. Since the screen is taller than it is wide, +/-1 in the Y axis is not going to be completely at the bottom or top.
  func getScaledPosition(_ normalizedPosition: CGPoint) -> CGPoint {
    let halfScaleValue = getScaleValue() / 2.0
    return CGPoint(x: halfScaleValue * normalizedPosition.x, y: halfScaleValue * normalizedPosition.y)
  }
  
  // Returns a vector scaled by the scaling value.
  func getScaledVector(_ normalizedVector: CGVector) -> CGVector {
    return CGVector(dx: getScaledValue(normalizedVector.dx), dy: getScaledValue(normalizedVector.dy))
  }
  
  // Given a normalized value (e.g. speed), returns the absolute speed by scaling it up with the size of the world (which is dictated by the screen size of the device).
  func getScaledValue(_ normalizedValue: CGFloat) -> CGFloat {
    return normalizedValue * getScaleValue()
  }
  
  // Returns the scale value (not a scaled value, but rather the scaling factor itself).
  func getScaleValue() -> CGFloat {
    return self.frame.height
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
  // Events and phasing methods.
  //------------------------------------------------------------------------------
  
  // Creates a new EventPhase with this GameScene as the parent.
  func createEventPhase() -> EventPhase {
    let phase = EventPhase(gameScene: self)
    return phase
  }
  
  // Adds a sequence of phases to the level, starting the first phase.
  func setPhaseSequence(_ phaseSequence: EventPhase...) {
    self.eventPhaseSequence = phaseSequence
    if self.eventPhaseSequence.count > 1 {
      for i in 1 ..< self.eventPhaseSequence.count {
        self.eventPhaseSequence[i - 1].setNextPhase(to: self.eventPhaseSequence[i])
      }
    }
  }
  
  // Sets the next phase and uses its GameState to update for all future phases. Only if a phase is reset do we drop the last GameState and re-use the original one.
  func setNextPhase(to nextPhase: EventPhase) {
    self.currentPhase = nextPhase
    self.previousGameState = GameState(copyFrom: GameScene.gameState)
  }
  
  // Returns the current phase or nil if there is no current phase.
  func getCurrentPhase() -> EventPhase? {
    return self.currentPhase
  }
  
  // Starts the level, triggering the first phase.
  func start(withCountdown countdownTime: Int = 0) {
    if countdownTime > 0 {
      let countdownPhase = CountdownPhase(withDuration: countdownTime, gameScene: self)
      if !self.eventPhaseSequence.isEmpty {
        countdownPhase.setNextPhase(to: self.eventPhaseSequence.first!)
      }
      self.eventPhaseSequence.insert(countdownPhase, at: 0)
    }
    
    // Add the finish phase, which handles moving on to the next GameScene.
    // TODO: This should allow chaining levels, instead of always going to the main menu.
    let finishLevelPhase = createEventPhase()
    finishLevelPhase.execute(action: SetGameScene(to: "main menu"))
    self.eventPhaseSequence.last?.setNextPhase(to: finishLevelPhase)
    self.eventPhaseSequence.append(finishLevelPhase)
    
    if let firstPhase = self.eventPhaseSequence.first {
      firstPhase.start()
      setNextPhase(to: firstPhase)
    }
  }
  
  // Resets the scene. This clears all nodes and resets the background. Individual levels should extend this method and call other functions, such as createPlayer() and createGUI() if desired.
  func reset() {
    self.removeAllChildren()
    if let worldNode = self.worldNode {
      worldNode.removeAllChildren()
      addChild(worldNode)
    }
    // Reset the current phase, but preserve the player's gained experience.
    if let previousGameState = self.previousGameState {
      let playerExperience = GameScene.gameState.getPlayerStatus().getTotalPlayerExperience()
      GameScene.gameState = GameState(copyFrom: previousGameState)
      GameScene.gameState.getPlayerStatus().setPlayerExperience(to: playerExperience)
    }
    self.currentPhase?.start()
  }
  
  //------------------------------------------------------------------------------
  // Touch event methods.
  //------------------------------------------------------------------------------
  
  private func touchDown(atPoint pos: CGPoint) {
    let touchedNodes: [SKNode] = nodes(at: pos)
    GameScene.gameState.inform(.screenTouchDown, value: ScreenTouchInfo(pos, touchedNodes))
    self.lastTouchPosition = pos
  }
  
  private func touchMoved(toPoint pos: CGPoint) {
    let touchedNodes: [SKNode] = nodes(at: pos)
    GameScene.gameState.inform(.screenTouchMoved, value: ScreenTouchInfo(pos, touchedNodes))
    self.lastTouchPosition = pos
  }
  
  private func touchUp(atPoint pos: CGPoint) {
    let touchedNodes: [SKNode] = nodes(at: pos)
    GameScene.gameState.inform(.screenTouchUp, value: ScreenTouchInfo(pos, touchedNodes))
    self.lastTouchPosition = pos
  }
  
  // Returns the absolute screen pixel position of the most recent touch event (touch down/moved/up). If no touch events occured, returns a default location point of (0, 0).
  func getLastTouchPosition() -> CGPoint {
    if let lastTouchPosition = self.lastTouchPosition {
      return lastTouchPosition
    }
    return CGPoint(x: 0.0, y: 0.0)
  }
  
  // Stops any ongoing touch actions acting on the scene.
  func releaseAllTouches() {
    touchUp(atPoint: getLastTouchPosition())
  }
  
  //------------------------------------------------------------------------------
  // Scene management and cleanup methods.
  //------------------------------------------------------------------------------
  
  // Removes all nodes that are no longer on the screen. For example, if a bullet flies off the screen, there is no reason to track or update it anymore. It's gone.
  private func removeOffscreenNodes() {
    if let worldNode = self.worldNode {
      removeOffscreenNodes(from: worldNode)
    } else {
      removeOffscreenNodes(from: self)
    }
  }
  // Helper method for removeOffscreenNodes() above.
  private func removeOffscreenNodes(from parentNode: SKNode) {
    parentNode.enumerateChildNodes(withName: "bullet", using: { (node, stop) -> Void in
      if !parentNode.intersects(node) {
        if let gameObject = node.userData?.value(forKey: GameObject.nodeValueKey) as? GameObject {
          gameObject.destroyObject()
        }
      }
    })
  }
  
  //------------------------------------------------------------------------------
  // Animation update methods.
  //------------------------------------------------------------------------------
  
  // This method measures the elapsed time since the last frame and updates the current game level.
  // Called before each frame is rendered with the current time.
  override func update(_ currentTime: TimeInterval) {
    self.lastFrameTime = currentTime
    self.removeOffscreenNodes()
  }
  
  //------------------------------------------------------------------------------
  // SKScene multitouch handlers.
  //------------------------------------------------------------------------------
  
  // Called when user starts a touch action.
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches {
      touchDown(atPoint: t.location(in: self))
    }
  }
  
  // Called when user moves (drags) during a touch action.
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches {
      touchMoved(toPoint: t.location(in: self))
    }
  }
  
  // Called when user finishes a touch action.
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches {
      touchUp(atPoint: t.location(in: self))
    }
  }
  
  // Called when a touch action is interrupted or otherwise cancelled.
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    for t in touches {
      touchUp(atPoint: t.location(in: self))
    }
  }
  
  //------------------------------------------------------------------------------
  // Methods for EventCaller protocol.
  //------------------------------------------------------------------------------
  
  func when(_ event: Event) -> Event {
    event.setCaller(to: self)
    event.startTrackingStopCriteria()
    event.start()
    return event
  }
  
  func execute(action: EventAction) {
    action.setCaller(to: self)
    action.execute()
  }
  
  //------------------------------------------------------------------------------
  // Methods for GameStateListener protocol.
  //------------------------------------------------------------------------------
  
  // Subscribe this GameScene to all relevant game state changes that it needs to handle. Extend as needed with custom subscriptions for a given level.
  func subscribeToStateChanges() {
    // User actions:
    GameScene.gameState.subscribe(self, to: .pauseGame)
    GameScene.gameState.subscribe(self, to: .resumeGame)
    // Player events:
    GameScene.gameState.subscribe(self, to: .playerPosition)
    // Spawning and visual effect creation events:
    GameScene.gameState.subscribe(self, to: .spawnPlayerBullet)
    GameScene.gameState.subscribe(self, to: .spawnEnemyBullet)
    GameScene.gameState.subscribe(self, to: .createParticleEffect)
    // Level tracking:
    GameScene.gameState.subscribe(self, to: .spawnEnemy)
  }

  // When a game state change is reported, handle it here. Extend as needed with custom handlers for a given level.
  //
  // TODO: Some of these might work better as separate functions, specific EventActions that handle all the mechanics, or even factory objects to make the code cleaner.
  func reportStateChange(key: GameStateKey, value: Any) {
    switch key {
    case .pauseGame:
      pauseGame()
    case .resumeGame:
      resumePausedGame()
    case .playerPosition:
      // If player moves, update the world node position.
      if let position = value as? CGPoint, let worldNode = self.worldNode {
        let relativePositioning = (2 * position.x) / self.frame.width  // -1 to +1
        let widthDifference = worldNode.frame.width - self.frame.width
        let newWorldPosition = -relativePositioning * (widthDifference / 2)
        worldNode.position.x = newWorldPosition
      }
    case .spawnPlayerBullet, .spawnEnemyBullet:
      // Add spawned physics-enabled objects to the game.
      if let gameObject = value as? PhysicsEnabledGameObject {
        addGameObject(gameObject, withPhysicsScaling: true)
        gameObject.setDefaultVelocity()
      }
    case .createParticleEffect:
      // Add particle effects nodes.
      if let emitter = value as? SKEmitterNode {
        if let worldNode = self.worldNode {
          emitter.targetNode = worldNode
          worldNode.addChild(emitter)
        } else {
          addChild(emitter)
        }
      }
    case .spawnEnemy:
      // When an enemy spawns, increment the GameState's counter.
      let numEnemiesSpawned = GameScene.gameState.getInt(forKey: .numSpawnedEnemies)
      GameScene.gameState.set(.numSpawnedEnemies, to: numEnemiesSpawned + 1)
    default:
      break
    }
  }
}
