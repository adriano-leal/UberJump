//
//  GameScene.swift
//  UberJump
//
//  Created by Adriano Ramos on 30/04/19.
//  Copyright © 2019 Adriano Ramos. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Height at which levels end (stores the height or y-value that the player must reach to finish the level)
    var endLevelY = 0
    
    // Tap to Start
    let tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
    
    // Player
    var player: SKNode!
    
    // Layered Nodes
    var backgroundNode: SKNode!
    var midgroundNode: SKNode!
    var foregroundNode: SKNode!
    var hudNode: SKNode!
    
    // Labels for Score and Stars
    var lblScore: SKLabelNode!
    var lblStars: SKLabelNode!
    
    // scaleFactor ensures that graphics are scaled and positioned properly across all iPhone models.
    var scaleFactor: CGFloat!
    
    // Motion manager for accelerometer | Motion Manager to access the device's accelerometer data
    let motionManager = CMMotionManager()
    // ... and we'll store the most recently calculated acceleration value in xAcceleration
    // Acceleration value from accelerometer
    var xAcceleration: CGFloat = 0.0
    // ... which we'll use later to set the player node's velocity along the x-axis
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func createMidgroundNode() -> SKNode {
        // Create the node
        let theMidgroundNode = SKNode()
        var anchor: CGPoint!
        var xPosition: CGFloat!
        
        // 1 (Add some branches to the midground)
        for index in 0...9 {
            var spriteName: String
            // 2
            let r = arc4random() % 2
            if r > 0 {
                spriteName = "BranchRight"
                anchor = CGPoint(x: 1.0, y: 0.5)
                xPosition = self.size.width
            } else {
                spriteName = "BranchLeft"
                anchor = CGPoint(x: 0.0, y: 0.5)
                xPosition = 0.0
            }
            // 3
            let branchNode = SKSpriteNode(imageNamed: spriteName)
            branchNode.anchorPoint = anchor
            branchNode.position = CGPoint(x: xPosition, y: 500.0 * CGFloat(index))
            theMidgroundNode.addChild(branchNode)
        }
        // Return the completedmidground node
        return theMidgroundNode
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
        
        // Add the Midground
        midgroundNode = createMidgroundNode()
        addChild(midgroundNode)
        
        // Foreground (Primeiro Plano)
        foregroundNode = SKNode()
        addChild(foregroundNode)
        
        // HUD
        hudNode = SKNode()
        addChild(hudNode)
        
        // Load THE LEVEL
        let levelPlist = Bundle.main.path(forResource: "Level01", ofType: "plist")
        let levelData = NSDictionary(contentsOfFile: levelPlist!)!
        
        // Add a Star
//        let star = createStarAtPosition(position: CGPoint(x: 160, y: 220), ofType: .Special)
//        foregroundNode.addChild(star)
        let stars = levelData["Stars"] as! NSDictionary
        let starPatterns = stars["Patterns"] as! NSDictionary
        let starPositions = stars["Positions"] as! [NSDictionary]
        
        for starPosition in starPositions {
            let patternX = (starPosition["x"] as AnyObject).floatValue
            let patternY = (starPosition["y"] as AnyObject).floatValue
            let pattern = starPosition["pattern"] as! NSString
            
            // Look up the Pattern
            let starPattern = starPatterns[pattern] as! [NSDictionary]
            for starPoint in starPattern {
                let x = (starPoint["x"] as AnyObject).floatValue
                let y = (starPoint["y"] as AnyObject).floatValue
                let type = StarType(rawValue: (starPoint["type"]! as AnyObject).integerValue)
                let positionX = CGFloat(x! + patternX!)
                let positionY = CGFloat(y! + patternY!)
                let starNode = createStarAtPosition(position: CGPoint(x: positionX, y: positionY), ofType: type!)
                foregroundNode.addChild(starNode)
            }
        }
        
        // Height at which the player ends the level
        endLevelY = (levelData["EndY"]! as AnyObject).integerValue!
        
        // The code above loads the data from the property list (plist) into a dictionary named levelData and stores the property list's EndY value //in endLevelY.
        
        
        // Add Platform
//        let platform = createPlatformAtPosition(position: CGPoint(x: 160, y: 320), ofType: .Normal)
//        foregroundNode.addChild(platform)
        
        let platforms = levelData["Platforms"] as! NSDictionary
        let platformPatterns = platforms["Patterns"] as! NSDictionary
        let platformPositions = platforms["Positions"] as! [NSDictionary]
        
        for platformPosition in platformPositions {
            let patternX = (platformPosition["x"] as AnyObject).floatValue
            let patternY = (platformPosition["y"] as AnyObject).floatValue
            let pattern = platformPosition["pattern"] as! NSString
            
            // Look up the Pattern
            let platformPattern = platformPatterns[pattern] as! [NSDictionary]
            for platformPoint in platformPattern {
                let x = (platformPoint["x"] as AnyObject).floatValue
                let y = (platformPoint["y"] as AnyObject).floatValue
                let type = PlatformType(rawValue: (platformPoint["type"]! as AnyObject).integerValue)
                let positionX = CGFloat(x! + patternX!)
                let positionY = CGFloat(y! + patternY!)
                let platformNode = createPlatformAtPosition(position: CGPoint(x: positionX, y: positionY), ofType: type!)
                foregroundNode.addChild(platformNode)
            }
        }
        
        /* Above we are loading the Platforms dictionary from levelData and then looping through its Positions array. For each item in the array, we load the relevant pattern and instantiate a PlatformNode of the correct type at the specified (x, y) positions. We add all the platform nodes to the foreground node, where all the game objects belong.*/

        
        // Add the player
        player = createPlayer()
        foregroundNode.addChild(player)
        
        // Tap to Start
        tapToStartNode.position = CGPoint(x: self.size.width/2, y: 180.0)
        hudNode.addChild(tapToStartNode)
        
        // Building the HUD
        // 1 Stars
        let star = SKSpriteNode(imageNamed: "Star")
        star.position = CGPoint(x: 25, y: self.size.height - 30)
        hudNode.addChild(star)
        // 2
        lblStars = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        lblStars.fontSize = 30
        lblStars.fontColor = SKColor.white
        lblStars.position = CGPoint(x: 50, y: self.size.height - 40)
        lblStars.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        // 3
        lblStars.text = String(format: "X %d", GameState.sharedInstance.stars)
        hudNode.addChild(lblStars)
        
        // SCORE
        // 4
        lblScore = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        lblScore.fontSize = 30
        lblScore.fontColor = SKColor.white
        lblScore.position = CGPoint(x: self.size.width - 20, y: self.size.height - 40)
        lblScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.right
        // 5
        lblScore.text = "0"
        hudNode.addChild(lblScore)
        
        
        // CORE MOTION (Using Accelerometer)
        // 1
        motionManager.accelerometerUpdateInterval = 0.2
        // 2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) {
            (accelerometerData: CMAccelerometerData?, error: Error?) in
            // 3
            guard let accelerometerData = accelerometerData else { return }
            let acceleration = accelerometerData.acceleration
            // 4
            self.xAcceleration = (CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)
        }
        
//        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: {
//            (accelerometerData: CMAccelerometerData!, error: NSError!) in
//            // 3
//            let acceleration = accelerometerData.acceleration
//            // 4
//            self.xAcceleration = (CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)
//        })
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
    
    override func update(_ currentTime: TimeInterval) {
        // Calculate Player y offset
        if player.position.y > 200.0 {
            backgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200.0)/10))
            midgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200.0)/4))
            foregroundNode.position = CGPoint(x: 0.0, y: -(player.position.y - 200))
        }
    }
    
    override func didSimulatePhysics() {
        //1 Set velocity based on x-axis acceleration
        player.physicsBody?.velocity = CGVector(dx: xAcceleration * 400.0, dy: player.physicsBody!.velocity.dy)
        // 2 Check x bounds
        if player.position.x < -20.0 {
            player.position = CGPoint(x: self.size.width + 20.0, y: player.position.y)
        } else if (player.position.x > self.size.width + 20.0) {
            player.position = CGPoint(x: -20, y: player.position.y)
        }
    }
    
    
    // HUD -> Heads Up Display
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
