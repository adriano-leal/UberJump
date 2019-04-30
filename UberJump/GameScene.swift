//
//  GameScene.swift
//  UberJump
//
//  Created by Adriano Ramos on 30/04/19.
//  Copyright © 2019 Adriano Ramos. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Tap to Start
    let tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
    
    // Player
    var player: SKNode!
    
    // Layered Nodes
    var backgroundNode: SKNode!
    var midgroundNode: SKNode!
    var foregroundNode: SKNode!
    var hudNode: SKNode!
    
    // scaleFactor ensures that graphics are scaled and positioned properly across all iPhone models.
    var scaleFactor: CGFloat!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func createBackgroundNode() -> SKNode {
        // 1
        // Create the node
        let backgroundNode = SKNode()
        let ySpacing = 64.0 * scaleFactor
        
        // 2
        // Go through images until the entire background is built
        for index in 0...19 {
            // 3
            let node = SKSpriteNode(imageNamed:String(format: "Background%02d", index + 1))
            // 4
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: self.size.width / 2, y: ySpacing * CGFloat(index))
            //5
            backgroundNode.addChild(node)
        }
        
        // 6
        // Return the completed background node
        return backgroundNode
    }
    
    func createPlayer() -> SKNode {
        let playerNode = SKNode()
        playerNode.position = CGPoint(x: self.size.width/2, y: 80.0)
        
        let sprite = SKSpriteNode(imageNamed: "Player")
        playerNode.addChild(sprite)
        
        //Adding Physics Body to the Player
        //1
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width/2)
        //2
        playerNode.physicsBody?.isDynamic = false
        //3 - falso to keep the player upright (Use true on game over scene!)
        playerNode.physicsBody?.allowsRotation = false
        //4
        playerNode.physicsBody?.restitution = 1.0
        playerNode.physicsBody?.friction = 0.0
        playerNode.physicsBody?.angularDamping = 0.0
        playerNode.physicsBody?.linearDamping = 0.0
        
        
        // 1
        playerNode.physicsBody?.usesPreciseCollisionDetection = true
        // 2
        playerNode.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Player
        // 3
        playerNode.physicsBody?.collisionBitMask = 0
        // 4 we want to be informed when the player node touches any start or platforms !!!!!!!!!!!!
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Star | CollisionCategoryBitmask.Platform
        
        return playerNode
    }
    
    
    func createStarAtPosition(position: CGPoint, ofType type: StarType) -> StarNode {
        
        // 1 Instantiating StarNode and setting its position
        let node = StarNode()
        let thePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.position = thePosition
        node.name = "NODE_STAR"
        node.starType = type
        
        // 2 assigning the stars graphic using SKSpriteNode
        var sprite: SKSpriteNode
        if type == .Special {
            sprite = SKSpriteNode(imageNamed: "StarSpecial")
        } else {
            sprite = SKSpriteNode(imageNamed: "Star")
        }
        node.addChild(sprite)
        
        // 3 Setting a circular physics body
        node.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width/2)
        
        // 4 Making the physics body static
        node.physicsBody?.isDynamic = false
        
        
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Star
        node.physicsBody?.collisionBitMask = 0
        return node
    }
    
    func createPlatformAtPosition(position: CGPoint, ofType type: PlatformType) -> PlatformNode {
        // 1
        let node = PlatformNode()
        let thePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.position = thePosition
        node.name = "NODE_PLATFORM"
        node.platformType = type
        
        // 2
        var sprite: SKSpriteNode
        if type == .Break {
            sprite = SKSpriteNode(imageNamed: "PlatformBreak")
        } else {
            sprite = SKSpriteNode(imageNamed: "Platform")
        }
        node.addChild(sprite)
        
        // 3
        node.physicsBody = SKPhysicsBody(rectangleOf: sprite.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Platform
        node.physicsBody?.collisionBitMask = 0
        
        return node
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.white
        
        // Add some Gravity && Registering the scene to receive contact notifications
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        physicsWorld.contactDelegate = self
        
        scaleFactor = self.size.width / 320.0
        
        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)
        
        // Foreground (Primeiro Plano)
        foregroundNode = SKNode()
        addChild(foregroundNode)
        
        // HUD
        hudNode = SKNode()
        addChild(hudNode)
        
        // Add a Star
        let star = createStarAtPosition(position: CGPoint(x: 160, y: 220), ofType: .Special)
        foregroundNode.addChild(star)
        
        // Add Platform
        let platform = createPlatformAtPosition(position: CGPoint(x: 160, y: 320), ofType: .Normal)
        foregroundNode.addChild(platform)
        
        // Add the player
        player = createPlayer()
        foregroundNode.addChild(player)
        
        // Tap to Start
        tapToStartNode.position = CGPoint(x: self.size.width/2, y: 180.0)
        hudNode.addChild(tapToStartNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //1 (If were already playing, ignore touches)
        if player.physicsBody!.isDynamic{
            return
        }
        
        //2 - Remove the tap to Start node
        tapToStartNode.removeFromParent()
        
        //3 - Start the player by putting them into the physics simulation
        player.physicsBody?.isDynamic = true
        
        //4
        player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 20.0))
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        // 1
        var updateHUD = false
        
        // 2
        let whichNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
        let other = whichNode as! GameObjectNode
        
        // 3
        updateHUD = other.collisionWithPlayer(player: player)
        
        // Update the HUD if necessary
//        if updateHUD {
//            // 4 TODO
//        }
    }
}
