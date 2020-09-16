//
// Created by Joel Burton on 9/8/20.
// Copyright (c) 2020 Joel Burton. All rights reserved.
//

import UIKit
import SpriteKit

class Ball: SKSpriteNode {
    var x: Int!
    var y: Int!
    var cluster = LinkedList<Ball>()

    func configure(color: String, x: Int, y: Int) {
        self.name = color
        self.physicsBody?.angularDamping = 0
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.size.width / 2)
        setPosition(x: x, y: y)
    }

    func setPosition(x: Int, y: Int) {
        self.x = x
        self.y = y
        self.position = CGPoint(x: x * 46 + 50, y: y * 46 + 50)
    }

    func spin() {
        self.physicsBody?.angularVelocity = 5
        self.physicsBody?.angularDamping = 0
    }

    func stopSpin() {
        self.physicsBody?.angularDamping = 3
    }
}
