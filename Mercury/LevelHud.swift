//
//  PlayerHud.swift
//  Mercury
//
//  Created by Richard Teammco on 4/7/17.
//  Copyright © 2017 Richard Teammco. All rights reserved.
//
//  The LevelHud handles displaying information about the player and level.

import SpriteKit

class LevelHud: GameObject {
  
  var barWidth: CGFloat?
  var healthBarNode: SKShapeNode?
  var healthBarText: SKLabelNode?
  var experienceBarNode: SKShapeNode?
  var playerLevelTextNode: SKLabelNode?
  
  init() {
    super.init(position: CGPoint(x: 0, y: 0))
    GameScene.gameState.subscribe(self, to: .playerHealth)
    GameScene.gameState.subscribe(self, to: .playerDied)
    GameScene.gameState.subscribe(self, to: .playerExperienceChange)
  }
  
  // Updates when player health changes or when player dies.
  override func reportStateChange(key: GameStateKey, value: Any) {
    switch key {
    case .playerHealth, .playerDied:
      updateHealthBar()
    case .playerExperienceChange:
      updateLevelAndExperienceBar()
    default:
      break
    }
  }
  
  // Updates the health bar and text given the ratio of health (ratio between max health and the current health). Ratio will always be normalized between 0 and 1.
  private func updateHealthBar() {
    let currentHealth = GameScene.gameState.getCGFloat(forKey: .playerHealth)
    var ratio: CGFloat = currentHealth / GameScene.gameState.getPlayerStatus().getMaxPlayerHealth()
    if ratio > 1.0 {
      ratio = 1.0
    } else if ratio < 0.0 {
      ratio = 0.0
    }
    self.healthBarNode?.xScale = ratio
    if ratio > 0 {
      let percent = Int(round(100 * ratio))
      self.healthBarText?.text = String(percent) + "%"
    } else {
      self.healthBarText?.text = "x_x"
    }
  }
  
  // Updates the player level display experience bar visualization based on the given playerStatus variable.
  private func updateLevelAndExperienceBar() {
    let playerStatus = GameScene.gameState.getPlayerStatus()
    var ratio = CGFloat(playerStatus.getCurrentPlayerExperience()) / CGFloat(playerStatus.playerExperienceRequiredToNextLevel())
    if ratio > 1.0 {
      ratio = 1.0
    } else if ratio < 0.0 {
      ratio = 0.0
    }
    if let experienceBar = self.experienceBarNode {
      experienceBar.xScale = ratio
      if let barWidth = self.barWidth {
        let xOffset: CGFloat = (barWidth * (1.0 - ratio)) / 2.0
        experienceBar.position.x = -xOffset
      }
    }
    self.playerLevelTextNode?.text = String(playerStatus.getPlayerLevel())
  }
  
  // Sets up the HUD node, which contains children nodes (the health bar and text) that get updated as the level continues.
  override func createGameSceneNode(scale: CGFloat) -> SKNode {
    // The HUD node itself is just the outline of the health bar. We will add things in and around it.
    let width = GameConfiguration.hudBarWidth * scale
    self.barWidth = width
    let height = GameConfiguration.hudBarHeight * scale
    let hudNode = SKShapeNode(rectOf: CGSize(width: width, height: height))
    hudNode.position = CGPoint(x: 0, y: scale * GameConfiguration.hudBarYPosition)
    hudNode.lineWidth = GameConfiguration.hudBarOutlineWidth
    hudNode.strokeColor = SKColor.red
    
    // Create the health bar part of the HUD.
    let healthBarNode = SKShapeNode(rectOf: CGSize(width: width, height: height))
    healthBarNode.position = CGPoint(x: 0, y: 0)  // Centered on the HUD node.
    healthBarNode.fillColor = GameConfiguration.hudHealthBarColor
    healthBarNode.alpha = GameConfiguration.hudBarAlpha
    self.healthBarNode = healthBarNode
    hudNode.addChild(healthBarNode)
    
    // Create the text (health %) in the node.
    let healthBarText = SKLabelNode(text: "100%")
    healthBarText.position = CGPoint(x: 0, y: 0)  // Centered on the HUD node.
    healthBarText.color = GameConfiguration.hudHealthTextColor
    healthBarText.fontName = GameConfiguration.hudHealthTextFont
    healthBarText.fontSize = GameConfiguration.hudHealthTextFontSize
    healthBarText.verticalAlignmentMode = .center
    self.healthBarText = healthBarText
    hudNode.addChild(healthBarText)
    
    // Create the XP bar.
    let experienceBarHeight = height * 0.2  // One fifth of the health bar height.
    let experienceBar = SKShapeNode(rectOf: CGSize(width: width, height: experienceBarHeight))
    experienceBar.position = CGPoint(x: 0, y: (height / 2.0 + GameConfiguration.hudBarOutlineWidth))  // Right above the HP bar.
    experienceBar.fillColor = GameConfiguration.hudExperienceBarColor
    experienceBar.alpha = GameConfiguration.hudBarAlpha
    self.experienceBarNode = experienceBar
    hudNode.addChild(experienceBar)
    
    // Create the player level text indicator.
    let playerLevelText = SKLabelNode(text: "??")
    playerLevelText.position = CGPoint(x: width / 1.8, y: 0)  // Left of the HP bar.
    playerLevelText.color = GameConfiguration.hudPlayerLevelTextColor
    playerLevelText.fontName = GameConfiguration.hudPlayerLevelTextFont
    playerLevelText.fontSize = GameConfiguration.hudPlayerLevelTextFontSize
    playerLevelText.verticalAlignmentMode = .center
    playerLevelText.horizontalAlignmentMode = .left
    self.playerLevelTextNode = playerLevelText
    hudNode.addChild(playerLevelText)
    
    // Set the current level and XP based on the current playerStatus.
    updateLevelAndExperienceBar()
    
    // Finally, create the pause button.
    let pauseButton = ButtonNode.interfaceButton(withText: "⏸")
    pauseButton.position = CGPoint(x: -width / 1.7, y: 0)  // Right of the HP bar.
    pauseButton.setCallback {
      GameScene.gameState.inform(.pauseGame)
    }
    hudNode.addChild(pauseButton)
    
    // Add the node to the scene.
    hudNode.zPosition = GameScene.zPositionForGUI
    self.gameSceneNode = hudNode
    return hudNode
  }
  
}
