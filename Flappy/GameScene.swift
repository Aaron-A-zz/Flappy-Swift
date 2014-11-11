//
//  GameScene.swift
//  Flappy
//
//  Created by Mav3r1ck on 11/11/14.
//  Copyright (c) 2014 Mav3r1ck. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bird = SKSpriteNode();
    var sprite = SKSpriteNode();
    var pipeUpTexture = SKTexture();
    var pipeDownTexture = SKTexture();
    var pipeMoveAndRemove = SKAction();
    var groundTexture = SKTexture();
    let pipeGap = 150.0;
    var moveGroundSpritesForever = SKAction();
    var skyColor = SKColor();
    
    var scoreLabelNode = SKLabelNode();
    var score = NSInteger();
    var reset = Bool();
    var pipes:SKNode!;
    var moving:SKNode!;
    
    let birdCategory:UInt32 = 1<<0
    let worldCategory:UInt32 = 1<<1
    let pipeCategory:UInt32 = 1<<2
    let scoreCategory:UInt32 = 1<<3
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        reset = false;
        
        self.physicsWorld.gravity = CGVectorMake(0.0, -5.0);
        self.physicsWorld.contactDelegate = self;
        
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0);
        self.backgroundColor = skyColor;
        
        moving = SKNode();
        self.addChild(moving);
        pipes = SKNode();
        moving.addChild(pipes);
        
        var birdTexture = SKTexture(imageNamed: "bird-01");
        birdTexture.filteringMode = SKTextureFilteringMode.Nearest;
        
        
        
        bird = SKSpriteNode(texture: birdTexture);
        bird.setScale(2);
        bird.position = CGPoint(x: self.frame.size.width*0.35, y: self.frame.size.height*0.6);
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/2);
        bird.physicsBody?.dynamic = true;
        bird.physicsBody?.allowsRotation = false;
        
        bird.physicsBody?.categoryBitMask = birdCategory;
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory;
        
        self.addChild(bird);
        
        groundTexture = SKTexture(imageNamed: "ground");
        groundTexture.filteringMode = SKTextureFilteringMode.Nearest;
        
        moveGround();
        
        for var i:CGFloat = 0; i<2.0 + self.frame.size.width/(groundTexture.size().width*2.0); i++ {
            sprite = SKSpriteNode(texture: groundTexture);
            sprite.setScale(2.0);
            sprite.position = CGPointMake(i*sprite.size.width, sprite.size.height/2);
            sprite.runAction(moveGroundSpritesForever);
            moving.addChild(sprite);
        }
        
        var ground = SKNode();
        ground.position = CGPointMake(0, groundTexture.size().height);
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTexture.size().height*2));
        ground.physicsBody?.dynamic = false;
        ground.physicsBody?.categoryBitMask = worldCategory;
        self.addChild(ground);
        
        pipeUpTexture = SKTexture(imageNamed: "pipeup");
        pipeDownTexture = SKTexture(imageNamed: "pipedown");
        pipeUpTexture.filteringMode = .Nearest;
        pipeDownTexture.filteringMode = .Nearest;
        
        let distanceToMove = CGFloat(self.frame.size.width * 2 * pipeUpTexture.size().width);
        let movePipes = SKAction.moveByX(-distanceToMove, y: 0, duration: NSTimeInterval(0.01*distanceToMove));
        let removePipes = SKAction.removeFromParent();
        
        pipeMoveAndRemove = SKAction.sequence([movePipes,removePipes]);
        
        
        //spawnpipes
        
        let spawn = SKAction.runBlock({() in self.spawnPipes()});
        let delay = SKAction.waitForDuration(NSTimeInterval(2.0));
        let spawnThenDelay = SKAction.sequence([spawn,delay]);
        let spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay);
        
        self.runAction(spawnThenDelayForever);
        
        
        
        //Score
        score = 0;
        scoreLabelNode = SKLabelNode(fontNamed: "Calibri");
        scoreLabelNode.position = CGPointMake(CGRectGetMidX(self.frame), 3*self.frame.size.height/4 + 100);
        scoreLabelNode.zPosition = 50;
        scoreLabelNode.text = String(score);
        self.addChild(scoreLabelNode);
        
    }
    
    func moveGround() {
        let moveGroundSprite = SKAction.moveByX(-groundTexture.size().width*2 , y: 0, duration: NSTimeInterval(0.007*groundTexture.size().width*2));
        let resetGroundSprite = SKAction.moveByX(groundTexture.size().width*2, y: 0, duration: 0);
        moveGroundSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]));
    }
    
    func spawnPipes() {
        let pipePair = SKNode();
        pipePair.position = CGPointMake(self.frame.size.width + pipeUpTexture.size().width * 2 , 0);
        
        pipePair.zPosition = -10;
        
        let height = UInt32(self.frame.size.height/4);
        let y = arc4random() % height + height;
        
        let pipeDown = SKSpriteNode(texture: pipeDownTexture);
        pipeDown.setScale(0.5);
        pipeDown.position = CGPointMake(0, CGFloat(y) + pipeDown.size.height + CGFloat(pipeGap));
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOfSize: pipeDown.size);
        pipeDown.physicsBody?.dynamic = false;
        pipeDown.physicsBody?.categoryBitMask = pipeCategory;
        pipeDown.physicsBody?.contactTestBitMask = birdCategory;
        pipePair.addChild(pipeDown);
        
        let pipeUp = SKSpriteNode(texture: pipeUpTexture);
        pipeUp.setScale(0.5);
        pipeUp.position = CGPointMake(0, CGFloat(y));
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOfSize: pipeUp.size);
        pipeUp.physicsBody?.dynamic = false;
        pipeUp.physicsBody?.categoryBitMask = pipeCategory;
        pipeUp.physicsBody?.contactTestBitMask = birdCategory;
        pipePair.addChild(pipeUp);
        
        var contactNode = SKNode();
        contactNode.position = CGPointMake(pipeDown.size.width+bird.size.width/2, CGRectGetMidY(self.frame));
        contactNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(pipeUp.size.width, self.frame.size.height));
        contactNode.physicsBody?.dynamic = false;
        contactNode.physicsBody?.categoryBitMask = scoreCategory;
        contactNode.physicsBody?.contactTestBitMask = birdCategory;
        pipePair.addChild(contactNode);
        
        pipePair.runAction(pipeMoveAndRemove);
        pipes.addChild(pipePair);
        
    }
    func gameReset()-> Void {
        bird.position = CGPointMake(self.frame.size.width*0.35, self.frame.size.height*0.6);
        bird.physicsBody?.velocity = CGVectorMake(0, 0);
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
        bird.speed = 1;
        bird.zRotation = 0;
        score = 0;
        reset = false;
        pipes.removeAllChildren();
        scoreLabelNode.text = String(score);
        moving.speed = 1;
    }
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        if(moving.speed > 0){
            for touch: AnyObject in touches {
                let location = touch.locationInNode(self);
                bird.physicsBody?.velocity = CGVectorMake(0, 0);
                bird.physicsBody?.applyImpulse(CGVectorMake(0, 25));
            }
        }else if reset{
            self.gameReset();
        }
    }
    func didBeginContact(contact: SKPhysicsContact) {
        if(moving.speed > 0){
            
            if(( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory ) {
                
                
                score++;
                print("anıl \(score)");
                scoreLabelNode.text = String(score);
                
                
                scoreLabelNode.runAction(SKAction.sequence([SKAction.scaleTo(1.5, duration: NSTimeInterval(0.1)),SKAction.scaleTo(1, duration: NSTimeInterval(0.1))]));
            }
            else {
                
                moving.speed = 0;
                bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory;
                bird.runAction(SKAction.rotateByAngle(CGFloat(M_PI)*CGFloat(bird.position.y)*0.01, duration:1), completion:{self.bird.speed = 0});
                
                self.removeActionForKey("bitir")
                self.runAction(SKAction.sequence([SKAction.repeatAction(SKAction.sequence([SKAction.runBlock({
                    self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
                }),SKAction.waitForDuration(NSTimeInterval(0.05)), SKAction.runBlock({
                    self.backgroundColor = self.skyColor
                }), SKAction.waitForDuration(NSTimeInterval(0.05))]), count:4), SKAction.runBlock({
                    self.reset = true
                })]), withKey: "bitir")
            }
        }
        
    }
    func clamp(min:CGFloat,max:CGFloat,value:CGFloat)->CGFloat {
        if(value>max){
            return max;
        }
        else if(value<min){
            return min;
        }
        else {
            return value;
        }
    }
    override func update(currentTime: CFTimeInterval) {
        
        bird.zRotation = self.clamp( -1, max: 0.5, value: bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001));
    }
}
