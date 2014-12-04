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
  let socket = Phoenix.Socket(endPoint: "ws://localhost:4000/ws")
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
        println("create my rocket")
        let name = message.valueFor("id")
        self.createMyRocket(name)
      }
      
      chan.on("player:move") { message in
        let name: String = message.valueFor("id")
        let move: String = message.valueFor("move")
        println("move player")
        self.moveRocket(name, move: move)
      }
      
      chan.on("user:entered") { message in
        println("create another rocket")
        let name: String = message.valueFor("id")
        self.createRocket(name)
      }
      
      chan.on("user:leave") { message in
        println("destroy rocket")
        self.destroyRocket()  
      }
    }
  }
  
  func moveRocket(name: String, move: String) {
    var guest: SKSpriteNode = childNodeWithName(name) as SKSpriteNode
    let point = convertMoveToPoint(move)
    let fly = SKAction.moveTo(point, duration: 0.5)
    guest.runAction(fly)
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
  
  func destroyRocket() {
  }
  
  override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    /* Called when a touch begins */
    for touch in touches {
      let clickPoint = touch.locationInNode(self)
      let fly = SKAction.moveTo(clickPoint, duration: 0.5)
      rocket.runAction(fly)
      let message = Phoenix.Message(message: ["user": "iDavid", "move":"\(clickPoint.x):\(clickPoint.y)"])
      let payload = Phoenix.Payload(channel: "rooms", topic: topic!, event: "player:move", message: message)
      socket.send(payload)
    }
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
