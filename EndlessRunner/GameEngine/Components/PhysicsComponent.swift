import GameplayKit
import SpriteKit

/// PhysicsComponent - Manages collision detection and physics simulation
/// Decouples physics from visuals for maximum reusability
class PhysicsComponent: GKComponent {
    let physicsBody: SKPhysicsBody

    // Render component dependency
    weak var renderComponent: RenderComponent?

    init(body: SKPhysicsBody) {
        self.physicsBody = body
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didAddToEntity() {
        super.didAddToEntity()

        // Automatic dependency injection - check for subclass first!
        // GameplayKit component(ofType:) doesn't find subclasses automatically
        if let spriteComp = entity?.component(ofType: SpriteRenderComponent.self) {
            renderComponent = spriteComp
        } else {
            renderComponent = entity?.component(ofType: RenderComponent.self)
        }

        if let node = renderComponent?.node {
            node.physicsBody = physicsBody
        }
    }

    // MARK: - Physics Configuration

    func setVelocity(_ velocity: CGVector) {
        physicsBody.velocity = velocity
    }

    func applyImpulse(_ impulse: CGVector) {
        physicsBody.applyImpulse(impulse)
    }

    func setBitmasks(category: UInt32, collision: UInt32, contact: UInt32) {
        physicsBody.categoryBitMask = category
        physicsBody.collisionBitMask = collision
        physicsBody.contactTestBitMask = contact
    }
}

// MARK: - Physics Category Bitmasks

struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1        // 1
    static let obstacle: UInt32 = 0b10     // 2
    static let ground: UInt32 = 0b100      // 4
    static let coin: UInt32 = 0b1000       // 8
    static let powerup: UInt32 = 0b10000   // 16
    static let boundary: UInt32 = 0b100000 // 32
}

// MARK: - Physics Factory (Optimized Colliders)

class PhysicsFactory {
    /// Circle collider - FASTEST collision detection
    static func createCircleBody(radius: CGFloat, dynamic: Bool = true) -> SKPhysicsBody {
        let body = SKPhysicsBody(circleOfRadius: radius)
        body.isDynamic = dynamic
        body.affectedByGravity = dynamic
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.0
        body.linearDamping = 0.0
        return body
    }

    /// Rectangle collider - Good for floors/walls
    static func createRectangleBody(size: CGSize, dynamic: Bool = false) -> SKPhysicsBody {
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = dynamic
        body.affectedByGravity = false
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.0
        return body
    }

    /// Edge body - For static boundaries (no collision resolution, only contact detection)
    static func createEdgeBody(from start: CGPoint, to end: CGPoint) -> SKPhysicsBody {
        let body = SKPhysicsBody(edgeFrom: start, to: end)
        body.isDynamic = false
        body.friction = 0.0
        return body
    }
}
