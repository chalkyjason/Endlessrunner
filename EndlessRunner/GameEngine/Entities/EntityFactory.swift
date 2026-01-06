import GameplayKit
import SpriteKit

/// EntityFactory - Centralized entity creation following ECS patterns
/// Creates entities with pre-configured component compositions
@MainActor
class EntityFactory {
    let gameManager: GameManager

    init(gameManager: GameManager) {
        self.gameManager = gameManager
    }

    // MARK: - Player Entity

    func createPlayer() -> GameEntity {
        let entity = GameEntity()
        entity.entityType = .player

        // Visual: BRIGHT CYAN square (smaller for better screen fit)
        let renderComponent = SpriteRenderComponent(
            shapeType: .square,
            color: SKColor.cyan,  // Bright cyan instead of system blue
            size: CGSize(width: 40, height: 40)  // Smaller for better gameplay
        )

        // Physics: Circle collider for smooth collisions
        let physicsBody = PhysicsFactory.createCircleBody(radius: 20, dynamic: true)
        physicsBody.mass = 1.0
        let physicsComponent = PhysicsComponent(body: physicsBody)
        physicsComponent.setBitmasks(
            category: PhysicsCategory.player,
            collision: PhysicsCategory.ground | PhysicsCategory.obstacle,
            contact: PhysicsCategory.obstacle | PhysicsCategory.coin | PhysicsCategory.powerup
        )

        // Movement: Stationary (world moves, player stays fixed)
        let locomotionComponent = JumpableLocomotionComponent(
            strategy: StationaryStrategy()
        )
        locomotionComponent.jumpImpulse = 1000  // Higher jump! Was 800

        // Input handling
        let inputComponent = InputComponent(gameManager: gameManager)

        // Add components
        entity.addComponent(renderComponent)
        entity.addComponent(physicsComponent)
        entity.addComponent(locomotionComponent)
        entity.addComponent(inputComponent)

        return entity
    }

    // MARK: - Obstacle Entities

    func createObstacle(type: ObstacleType) -> GameEntity {
        let entity = GameEntity()
        entity.entityType = .obstacle

        let (shapeType, color, size) = type.visualConfig

        let renderComponent = SpriteRenderComponent(
            shapeType: shapeType,
            color: color,
            size: size
        )

        // Physics: Circle collider (fastest)
        let radius = min(size.width, size.height) / 2
        let physicsBody = PhysicsFactory.createCircleBody(radius: radius, dynamic: false)
        let physicsComponent = PhysicsComponent(body: physicsBody)
        physicsComponent.setBitmasks(
            category: PhysicsCategory.obstacle,
            collision: PhysicsCategory.none,
            contact: PhysicsCategory.player
        )

        // Movement: Linear leftward motion
        let velocity = CGVector(dx: -300, dy: 0)  // Will be updated by game speed
        let locomotionComponent = LocomotionComponent(
            strategy: LinearMovementStrategy(velocity: velocity)
        )

        // Lifecycle: Auto-despawn when off-screen
        let lifecycleComponent = LifeCycleComponent(offscreenThreshold: -100)

        entity.addComponent(renderComponent)
        entity.addComponent(physicsComponent)
        entity.addComponent(locomotionComponent)
        entity.addComponent(lifecycleComponent)

        return entity
    }

    // MARK: - Coin Entity

    func createCoin() -> GameEntity {
        let entity = GameEntity()
        entity.entityType = .coin

        let renderComponent = SpriteRenderComponent(
            shapeType: .circle,
            color: .systemYellow,
            size: CGSize(width: 30, height: 30)
        )

        let physicsBody = PhysicsFactory.createCircleBody(radius: 15, dynamic: false)
        let physicsComponent = PhysicsComponent(body: physicsBody)
        physicsComponent.setBitmasks(
            category: PhysicsCategory.coin,
            collision: PhysicsCategory.none,
            contact: PhysicsCategory.player
        )

        let velocity = CGVector(dx: -300, dy: 0)
        let locomotionComponent = LocomotionComponent(
            strategy: LinearMovementStrategy(velocity: velocity)
        )

        let lifecycleComponent = LifeCycleComponent(offscreenThreshold: -100)

        entity.addComponent(renderComponent)
        entity.addComponent(physicsComponent)
        entity.addComponent(locomotionComponent)
        entity.addComponent(lifecycleComponent)

        return entity
    }

    // MARK: - Background Element

    func createBackgroundElement(layer: BackgroundLayer) -> GameEntity {
        let entity = GameEntity()
        entity.entityType = .background

        let (shapeType, color, size) = layer.visualConfig

        let renderComponent = SpriteRenderComponent(
            shapeType: shapeType,
            color: color,
            size: size
        )
        renderComponent.setAlpha(layer.alpha)
        renderComponent.setZPosition(layer.zPosition)

        // No physics for background
        let velocity = CGVector(dx: layer.scrollSpeed, dy: 0)
        let locomotionComponent = LocomotionComponent(
            strategy: LinearMovementStrategy(velocity: velocity)
        )

        entity.addComponent(renderComponent)
        entity.addComponent(locomotionComponent)

        return entity
    }
}

// MARK: - Obstacle Type Configuration

enum ObstacleType: Sendable {
    case spike
    case block
    case triangle
    case diamond
    case hexagon       // NEW: Geometry Dash style!
    case circle        // NEW: Bouncy circle
    case star          // NEW: Star obstacle
    case pillar        // NEW: Tall pillar

    var visualConfig: (ShapeType, SKColor, CGSize) {
        switch self {
        case .spike:
            // Deadly red spike - Sharp and dangerous!
            return (.triangle, SKColor(red: 1.0, green: 0.0, blue: 0.2, alpha: 1.0), CGSize(width: 55, height: 75))
        case .block:
            // Orange block - Classic square
            return (.square, SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0), CGSize(width: 65, height: 65))
        case .triangle:
            // Magenta triangle - Vibrant!
            return (.triangle, SKColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0), CGSize(width: 60, height: 60))
        case .diamond:
            // Pink diamond - Rotated square
            return (.diamond, SKColor(red: 1.0, green: 0.4, blue: 0.7, alpha: 1.0), CGSize(width: 55, height: 55))
        case .hexagon:
            // Cyan hexagon - Geometric and cool!
            return (.hexagon, SKColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0), CGSize(width: 70, height: 70))
        case .circle:
            // Yellow circle - Bouncy look
            return (.circle, SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0), CGSize(width: 60, height: 60))
        case .star:
            // White star - Bright and attention-grabbing
            return (.hexagon, SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), CGSize(width: 65, height: 65))
        case .pillar:
            // Blue tall pillar - Vertical obstacle
            return (.square, SKColor(red: 0.2, green: 0.4, blue: 1.0, alpha: 1.0), CGSize(width: 50, height: 100))
        }
    }
}

// MARK: - Background Layer Configuration

enum BackgroundLayer {
    case far
    case mid
    case near

    var scrollSpeed: CGFloat {
        switch self {
        case .far: return -30    // 10% of game speed
        case .mid: return -150   // 50% of game speed
        case .near: return -360  // 120% of game speed
        }
    }

    var visualConfig: (ShapeType, SKColor, CGSize) {
        switch self {
        case .far:
            return (.hexagon, SKColor.systemGray.withAlphaComponent(0.3), CGSize(width: 100, height: 100))
        case .mid:
            return (.diamond, SKColor.systemGray.withAlphaComponent(0.5), CGSize(width: 80, height: 80))
        case .near:
            return (.circle, SKColor.systemGray.withAlphaComponent(0.7), CGSize(width: 60, height: 60))
        }
    }

    var alpha: CGFloat {
        switch self {
        case .far: return 0.3
        case .mid: return 0.5
        case .near: return 0.7
        }
    }

    var zPosition: CGFloat {
        switch self {
        case .far: return -100
        case .mid: return -50
        case .near: return -10
        }
    }
}

