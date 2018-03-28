//
//  GameScene.swift
//  GameTest
//
//  Created by 高菘駿 on 2018/3/27.
//  Copyright © 2018年 SoJ. All rights reserved.
//

import SpriteKit
import GameplayKit

let BallCategoryName = "ball"
let ClapboardCategoryName = "clapboard"
let BlockCategoryName = "icecube"
let GameMessageName = "gameMessage"

let BallCategory   : UInt32 = 0x1 << 0
let LeftCategory   : UInt32 = 0x1 << 1
let BlockCategory  : UInt32 = 0x1 << 2
let ClapboardCategory : UInt32 = 0x1 << 3
let BorderCategory : UInt32 = 0x1 << 4

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var outsideCircle: SKShapeNode?
    var insideCircle: SKShapeNode?
    
    var isFingerOnScreen = false
    
    lazy var gameState: GKStateMachine = GKStateMachine(states: [
        WaitingForTap(scene: self),
        Playing(scene: self),
        GameOver(scene: self)])
    
    var gameWon : Bool = false {
        didSet {
            let gameOver = childNode(withName: GameMessageName) as! SKSpriteNode
            let textureName = gameWon ? "YouWon" : "GameOver"
            let texture = SKTexture(imageNamed: textureName)
            let actionSequence = SKAction.sequence([SKAction.setTexture(texture),
                                                    SKAction.scale(to: 1.0, duration: 0.25)])

            gameOver.run(actionSequence)
        }
    }

    
    // MARK: - Setup
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // 1.
        let borderBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        // 2.
        borderBody.friction = 0
        // 3.
        self.physicsBody = borderBody
        
        physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
        physicsWorld.contactDelegate = self
        
        let ball = childNode(withName: BallCategoryName) as! SKSpriteNode
//        ball.physicsBody!.applyImpulse(CGVector(dx: 1.0, dy: -5.0))
        
        
        let leftRect = CGRect(x: frame.origin.x,
                              y: 132,
                              width: 1,
                              height: 148)
        
        let left = SKNode()
        left.physicsBody = SKPhysicsBody(edgeLoopFrom: leftRect)
        addChild(left)
        
        let clapboard = childNode(withName: ClapboardCategoryName) as! SKSpriteNode
        
        left.physicsBody!.categoryBitMask = LeftCategory
        ball.physicsBody!.categoryBitMask = BallCategory
        clapboard.physicsBody!.categoryBitMask = ClapboardCategory
        borderBody.categoryBitMask = BorderCategory
        
//        ball.physicsBody!.contactTestBitMask = LeftCategory
        ball.physicsBody!.contactTestBitMask = LeftCategory | BlockCategory
        
        // 1
        let numberOfBlocks = 8
        let blockWidth = SKSpriteNode(imageNamed: "icecube").size.width
        let blockHeight = SKSpriteNode(imageNamed: "icecube").size.width
        let totalBlocksWidth = blockWidth * CGFloat(numberOfBlocks)
        let totalBlocksHeight = blockHeight * CGFloat(numberOfBlocks)
        // 2
        let xOffset = (frame.width - totalBlocksWidth) / 2
        let yOffset = (frame.height - totalBlocksHeight) / 2
        // 3
        let shuffledDistribution = GKShuffledDistribution(lowestValue: 1, highestValue: numberOfBlocks)
        for i in 0..<numberOfBlocks {
            let block = SKSpriteNode(imageNamed: "icecube")  //靜態物體，不會受力和衝量的影響。
            block.position = CGPoint(x: xOffset + CGFloat(i) * blockWidth,
                                     y: yOffset + CGFloat(shuffledDistribution.nextInt()) * blockHeight)
            
            block.physicsBody = SKPhysicsBody(rectangleOf: block.frame.size)
            block.physicsBody!.allowsRotation = false
            block.physicsBody!.friction = 0.0
            block.physicsBody!.affectedByGravity = false
            block.physicsBody!.isDynamic = false
            //            block.name = BlockCategoryName
            block.physicsBody!.categoryBitMask = BlockCategory
            block.zPosition = 2
            addChild(block)
        }
        
        // part II GameState
        let gameMessage = SKSpriteNode(imageNamed: "TapToPlay")
        gameMessage.name = GameMessageName
        gameMessage.position = CGPoint(x: frame.midX, y: frame.midY)
        gameMessage.zPosition = 4
        gameMessage.setScale(0.0)
        addChild(gameMessage)
        
        gameState.enter(WaitingForTap.self)
    }
    
      // MARK: Events
      override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        switch gameState.currentState {
        case is WaitingForTap:
            gameState.enter(Playing.self)
            isFingerOnScreen = true
            
        case is Playing:
            //創立虛擬搖桿
            if outsideCircle != nil {
                removeChildren(in: [outsideCircle!, insideCircle!])
            }
            
            let touch = touches.first
            let touchLocation = touch!.location(in: self)
            let centerPoint = CGPoint(x: touchLocation.x, y: touchLocation.y)
            
            outsideCircle = SKShapeNode(rectOf: CGSize(width: 100, height: 100), cornerRadius: 50)
            outsideCircle?.position = centerPoint
            outsideCircle?.lineWidth = 3
            outsideCircle?.strokeColor = .black
            outsideCircle?.fillColor = .darkGray
            outsideCircle?.alpha = 0.5
            outsideCircle?.zPosition = 3
            
            insideCircle = SKShapeNode(rectOf: CGSize(width: 50, height: 50), cornerRadius: 25)
            insideCircle?.position = centerPoint
            insideCircle?.lineWidth = 3 //軌跡寬度 = 線寬
            insideCircle?.strokeColor = .black //軌跡顏色 = 線的顏色
            insideCircle?.fillColor = .darkGray //軌跡內填滿顏色 = 圖片顏色
            insideCircle?.alpha = 0.5
            insideCircle?.zPosition = 3
            
            addChild(outsideCircle!)
            addChild(insideCircle!)
            
            isFingerOnScreen = true
            
        case is GameOver:
            let newScene = GameScene(fileNamed:"GameScene")
            newScene!.scaleMode = .aspectFit
            let reveal = SKTransition.flipVertical(withDuration: 0.5)
            self.view?.presentScene(newScene!, transition: reveal)
            
        default:
            break
        }
        
      }
    
      override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        switch gameState.currentState {
        case is Playing:
        //實作虛擬搖桿
        guard outsideCircle != nil else { break }
        for t in touches {
            let position = t.location(in: self)
            let moveX = position.x - outsideCircle!.position.x
                //.center.x
            let moveY = position.y - outsideCircle!.position.y
            let length = sqrt(moveX * moveX + moveY * moveY)
            if length < 50 {   //50是大圓的半徑
                insideCircle?.position = position
            }else{
                let outY = (50 * moveY)/length
                let outX = (50 * moveX)/length
                //print("Y:\(y)===X:\(x)")
                insideCircle?.position = CGPoint(x: outX + outsideCircle!.position.x,
                                               y: outY + outsideCircle!.position.y)
            }
            clapboardDidMove(moved: ((insideCircle?.position.y)! - (outsideCircle?.position.y)!) / 5)
        }
        default:
            break
        }
      }
    
    func clapboardDidMove(moved: CGFloat) {
            // 1.
            // 2.
//            let touch = touches.first
//            let touchLocation = touch!.location(in: self)
//            let previousLocation = touch!.previousLocation(in: self)
            // 3.
            let clapboard = childNode(withName: "clapboard") as! SKSpriteNode
            // 4.
            var clapboardY = clapboard.position.y + moved
            // 5.
            clapboardY = max(clapboardY, clapboard.size.height/2)
            clapboardY = min(clapboardY, size.height - clapboard.size.height/2)
            // 6.
            clapboard.position = CGPoint(x: clapboard.position.x, y: clapboardY)

    }
    
    //避免手勢中途失效，導致虛擬搖桿殘留
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        removeChildren(in: [outsideCircle!, insideCircle!])
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard outsideCircle != nil else { return }
        removeChildren(in: [outsideCircle!, insideCircle!])
    }
    
    override func update(_ currentTime: TimeInterval) {
        gameState.update(deltaTime: currentTime)
    }
    
      // MARK: - SKPhysicsContactDelegate
      func didBegin(_ contact: SKPhysicsContact) {
        if gameState.currentState is Playing {
            // 1.
            var firstBody: SKPhysicsBody
            var secondBody: SKPhysicsBody
            // 2.
            if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
              firstBody = contact.bodyA
              secondBody = contact.bodyB
            } else {
              firstBody = contact.bodyB
              secondBody = contact.bodyA
            }
            // 3.
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == LeftCategory {
//              print("Hit bottom. First contact has been made.")
                gameState.enter(GameOver.self)
                gameWon = false
            }
            //4.(part II )
            if firstBody.categoryBitMask == BallCategory && secondBody.categoryBitMask == BlockCategory {
                breakBlock(node: secondBody.node!)
//                if isGameWon() {
//                    gameState.enter(GameOver.self)
//                    gameWon = true
//                }
            }
        }
      }
    
    func breakBlock(node: SKNode) {
        let particles = SKEmitterNode(fileNamed: "BrokenPlatform")!
        particles.position = node.position
        particles.zPosition = 3
        addChild(particles)
        particles.run(SKAction.sequence([SKAction.wait(forDuration: 1.0),
                                         SKAction.removeFromParent()]))
        node.removeFromParent()
    }
    
    func randomFloat(from: CGFloat, to: CGFloat) -> CGFloat {
        let rand: CGFloat = CGFloat(Float(arc4random()) / 0xFFFFFFFF)
        return (rand) * (to - from) + from
    }
    
    func isGameWon() -> Bool {
        var numberOfBricks = 0
        self.enumerateChildNodes(withName: BlockCategoryName) {
            node, stop in
            numberOfBricks = numberOfBricks + 1
        }
        return numberOfBricks == 0
    }
}
