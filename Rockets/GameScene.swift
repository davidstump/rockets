//
//  GameScene.swift
//  Rockets
//
//  Created by David Stump on 12/3/14.
//  Copyright (c) 2014 David Stump. All rights reserved.
//

import SpriteKit
import Foundation

class GameScene: SKScene {
  let socket = Phoenix.Socket(endPoint: "ws://192.168.1.68:4000/ws")
  var topic: String? = "lobby"
  var rocket = SKSpriteNode()
  
  override func didMoveToView(view: SKView) {
    channelListeners()
  }
  
  func channelListeners() {
    // Join the socket and establish handlers for users entering and submitting messages
    socket.join("rooms", topic: topic!, message: Phoenix.Message(subject: "status", body: "joining")) { channel in
      let chan = channel as Phoenix.Channel
      
      chan.on("join") { message in
        let name = message.valueFor("id")
        self.createMyRocket(name)
      }
      
      chan.on("player:move") { message in
        let name: String = message.valueFor("id")
        let move: String = message.valueFor("move")
        self.moveRocket(name, move: move)
      }
      
      chan.on("user:entered") { message in
        let name: String = message.valueFor("id")
        self.createRocket(name)
      }
      
      chan.on("user:leave") { message in
        let name = message.valueFor("id")
        self.destroyRocket(name)
      }
    }
  }
  
  func fly(sprite: SKSpriteNode, point: CGPoint) {
    let fly = SKAction.moveTo(point, duration: 0.5)
    rotateTowardTouch(point)
    sprite.runAction(fly)
  }
  
  func moveRocket(name: String, move: String) {
    if var guest: SKSpriteNode = childNodeWithName(name) as? SKSpriteNode {
      let point = convertMoveToPoint(move)
      fly(guest, point: point)
    } else {
      createRocket(name)
      moveRocket(name, move: move)
    }
  }
  
  func createMyRocket(name: String) {
    rocket = SKSpriteNode(imageNamed: "rocket")
    rocket.name = name
    
    rocket.xScale = 0.1
    rocket.yScale = 0.1
    
    rocket.position = CGPointMake(500, 400)
    
    self.addChild(rocket)
  }
  
  func createRocket(name: String) {
    let guest = SKSpriteNode(imageNamed: "rocket")
    guest.name = name
    
    guest.xScale = 0.1
    guest.yScale = 0.1
    
    guest.position = CGPointMake(500, 400)
    
    self.addChild(guest)
  }
  
  func destroyRocket(name: String) {
    if var guest: SKSpriteNode = childNodeWithName(name) as? SKSpriteNode {
        guest.removeFromParent()
    }
  }
  
  override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    /* Called when a touch begins */
    for touch in touches {
      let point = touch.locationInNode(self)
      fly(rocket, point: point)
      broadcastMove(rocket, point: point)
    }
  }
  
  func broadcastMove(ship: SKSpriteNode, point: CGPoint) {
    let message = Phoenix.Message(message: ["move":"\(point.x):\(point.y)", "id": "\(ship.name)"])
    let payload = Phoenix.Payload(channel: "rooms", topic: topic!, event: "player:move", message: message)
    socket.send(payload)
  }
  
  func rotateTowardTouch(point: CGPoint) {
    let deltaX: Float = Float(point.x - rocket.position.x)
    let deltaY: Float = Float(point.y - rocket.position.y)
    let angle = atan2f(deltaY, deltaX)
    let radians = CGFloat(angle - degreesToRadians(90.0))
    rocket.zRotation = radians
  }
  
  func degreesToRadians(angle: Float) -> Float {
    return angle * 0.01745329252
  }
   
  override func update(currentTime: CFTimeInterval) {
    /* Called before each frame is rendered */
  }
  
  func convertMoveToPoint(move: String) -> CGPoint {
    let position: Array = move.componentsSeparatedByString(":")
    let (positionX: Double, positionY: Double) = (doubleFromString(position[0])!, doubleFromString(position[1])!)
    let point = CGPoint(x: positionX, y: positionY)
    return point
  }
  
  func doubleFromString(string: String) -> Double? {
    return NSNumberFormatter().numberFromString(string)?.doubleValue
  }
}
