import GameplayKit
import SpriteKit

/// LocomotionComponent - Mathematical logic for movement
/// Swappable movement strategies for high reusability
class LocomotionComponent: GKComponent {
    var movementStrategy: MovementStrategy

    weak var renderComponent: RenderComponent?
    weak var physicsComponent: PhysicsComponent?

    init(strategy: MovementStrategy) {
        self.movementStrategy = strategy
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didAddToEntity() {
        super.didAddToEntity()
        renderComponent = entity?.component(ofType: RenderComponent.self)
        physicsComponent = entity?.component(ofType: PhysicsComponent.self)
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        guard let node = renderComponent?.node else { return }

        movementStrategy.update(node: node, deltaTime: seconds, physicsBody: physicsComponent?.physicsBody)
    }
}

// MARK: - Movement Strategy Protocol

protocol MovementStrategy {
    func update(node: SKNode, deltaTime: TimeInterval, physicsBody: SKPhysicsBody?)
    func reset()
}

// MARK: - Linear Movement (Standard Obstacle/Background)

class LinearMovementStrategy: MovementStrategy {
    var velocity: CGVector

    init(velocity: CGVector) {
        self.velocity = velocity
    }

    func update(node: SKNode, deltaTime: TimeInterval, physicsBody: SKPhysicsBody?) {
        if let body = physicsBody {
            body.velocity = velocity
        } else {
            // Direct position update for non-physics objects (backgrounds)
            node.position.x += velocity.dx * deltaTime
            node.position.y += velocity.dy * deltaTime
        }
    }

    func reset() {
        // No state to reset
    }

    func setVelocity(_ newVelocity: CGVector) {
        velocity = newVelocity
    }
}

// MARK: - Sine Wave Movement (Flying Enemies)

class SineWaveMovementStrategy: MovementStrategy {
    var baseVelocity: CGVector
    var amplitude: CGFloat
    var frequency: CGFloat
    private var elapsedTime: TimeInterval = 0
    private var initialY: CGFloat = 0
    private var hasSetInitialY: Bool = false

    init(baseVelocity: CGVector, amplitude: CGFloat, frequency: CGFloat) {
        self.baseVelocity = baseVelocity
        self.amplitude = amplitude
        self.frequency = frequency
    }

    func update(node: SKNode, deltaTime: TimeInterval, physicsBody: SKPhysicsBody?) {
        if !hasSetInitialY {
            initialY = node.position.y
            hasSetInitialY = true
        }

        elapsedTime += deltaTime

        // Horizontal movement
        node.position.x += baseVelocity.dx * deltaTime

        // Vertical sine wave
        let sineOffset = amplitude * sin(frequency * elapsedTime)
        node.position.y = initialY + sineOffset
    }

    func reset() {
        elapsedTime = 0
        hasSetInitialY = false
    }
}

// MARK: - Stationary Strategy (Player in Fixed-Position Design)

class StationaryStrategy: MovementStrategy {
    func update(node: SKNode, deltaTime: TimeInterval, physicsBody: SKPhysicsBody?) {
        // Player stays fixed; world moves around them
        // Only gravity affects vertical position via physics
    }

    func reset() {}
}

// MARK: - Jump State Management (For Player)

class JumpableLocomotionComponent: LocomotionComponent {
    var jumpImpulse: CGFloat = 800.0
    var isGrounded: Bool = true
    var maxJumps: Int = 2  // Double jump
    var jumpsRemaining: Int = 2

    func jump() {
        guard jumpsRemaining > 0 else { return }

        physicsComponent?.physicsBody.velocity.dy = 0  // Cancel existing vertical velocity
        physicsComponent?.applyImpulse(CGVector(dx: 0, dy: jumpImpulse))

        jumpsRemaining -= 1
        isGrounded = false
    }

    func resetJumps() {
        jumpsRemaining = maxJumps
        isGrounded = true
    }

    func land() {
        resetJumps()
    }
}
