import SpriteKit
import GameplayKit

/// GameScene - Core SpriteKit scene implementing side-scroller mechanics
/// Hybrid architecture: SpriteKit for rendering, SwiftUI for UI
@MainActor
class GameScene: SKScene {

    // MARK: - External State

    weak var gameManager: GameManager?

    // MARK: - ECS Systems

    private let systemManager = SystemManager()
    private let entityFactory: EntityFactory
    private let levelGenerator = LevelGenerator()

    // MARK: - Object Pools

    private lazy var obstaclePool = ObjectPool<GameEntity>(minPoolSize: 30) { [weak self] in
        guard let self = self else { return GameEntity() }
        return self.entityFactory.createObstacle(type: .spike)
    }

    private lazy var coinPool = ObjectPool<GameEntity>(minPoolSize: 20) { [weak self] in
        guard let self = self else { return GameEntity() }
        return self.entityFactory.createCoin()
    }

    // MARK: - Game Entities

    private var playerEntity: GameEntity!
    private var activeEntities: Set<ObjectIdentifier> = []

    // MARK: - Scene Layers (Parallax)

    private let backgroundLayer = SKNode()
    private let farLayer = SKNode()
    private let midLayer = SKNode()
    private let gameLayer = SKNode()  // Main play area
    private let foregroundLayer = SKNode()

    private var backgroundElements: [GameEntity] = []

    // MARK: - Ground

    private let groundNode = SKSpriteNode()
    private let groundHeight: CGFloat = 80

    // MARK: - Timing

    private var lastUpdateTime: TimeInterval = 0
    private var nextChunkSpawnX: CGFloat = 800

    // MARK: - Initialization

    init(size: CGSize, gameManager: GameManager) {
        self.gameManager = gameManager
        self.entityFactory = EntityFactory(gameManager: gameManager)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        setupScene()
        setupLayers()
        setupPhysics()
        setupGround()
        setupPlayer()
        setupBackground()
    }

    private func setupScene() {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        anchorPoint = CGPoint(x: 0, y: 0)
    }

    private func setupLayers() {
        // Z-ordering for parallax
        farLayer.zPosition = -100
        midLayer.zPosition = -50
        backgroundLayer.zPosition = -10
        gameLayer.zPosition = 0
        foregroundLayer.zPosition = 10

        addChild(farLayer)
        addChild(midLayer)
        addChild(backgroundLayer)
        addChild(gameLayer)
        addChild(foregroundLayer)
    }

    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -25)
        physicsWorld.contactDelegate = self

        // World boundaries
        let worldBoundary = CGRect(x: -100, y: 0, width: size.width + 200, height: size.height)
        physicsBody = SKPhysicsBody(edgeLoopFrom: worldBoundary)
        physicsBody?.categoryBitMask = PhysicsCategory.boundary
    }

    private func setupGround() {
        // Ground visual
        groundNode.color = SKColor.systemGray
        groundNode.size = CGSize(width: size.width * 3, height: groundHeight)
        groundNode.position = CGPoint(x: size.width / 2, y: groundHeight / 2)
        groundNode.zPosition = 1

        // Ground physics
        let groundBody = PhysicsFactory.createRectangleBody(
            size: CGSize(width: size.width * 3, height: groundHeight),
            dynamic: false
        )
        groundBody.categoryBitMask = PhysicsCategory.ground
        groundBody.collisionBitMask = PhysicsCategory.player
        groundNode.physicsBody = groundBody

        gameLayer.addChild(groundNode)
    }

    private func setupPlayer() {
        playerEntity = entityFactory.createPlayer()

        // Position: Fixed at 20% from left edge, above ground
        let playerX = size.width * 0.2
        let playerY = groundHeight + 100
        playerEntity.position = CGPoint(x: playerX, y: playerY)

        if let renderNode = playerEntity.renderNode {
            gameLayer.addChild(renderNode)
        }

        systemManager.registerEntity(playerEntity)
    }

    private func setupBackground() {
        // Create parallax background elements
        createParallaxLayer(layer: .far, count: 5, yRange: 300...500)
        createParallaxLayer(layer: .mid, count: 7, yRange: 200...400)
        createParallaxLayer(layer: .near, count: 10, yRange: 100...600)
    }

    private func createParallaxLayer(layer: BackgroundLayer, count: Int, yRange: ClosedRange<CGFloat>) {
        let targetLayer: SKNode = {
            switch layer {
            case .far: return farLayer
            case .mid: return midLayer
            case .near: return backgroundLayer
            }
        }()

        for i in 0..<count {
            let element = entityFactory.createBackgroundElement(layer: layer)
            let x = CGFloat(i) * (size.width / CGFloat(count - 1))
            let y = CGFloat.random(in: yRange)
            element.position = CGPoint(x: x, y: y)

            if let renderNode = element.renderNode {
                targetLayer.addChild(renderNode)
            }

            backgroundElements.append(element)
            systemManager.registerEntity(element)
        }
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        guard let manager = gameManager, manager.gameState == .playing, !manager.isPaused else {
            lastUpdateTime = currentTime
            return
        }

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // Update game speed
        manager.updateSpeed(deltaTime)
        manager.updateDistance(Double(manager.currentSpeed) * deltaTime / 100)

        // Update world velocity based on current speed
        updateWorldVelocity(speed: manager.currentSpeed)

        // Update all ECS systems
        systemManager.update(deltaTime: deltaTime)

        // Procedural generation
        checkAndSpawnChunks()

        // Background looping
        updateBackgroundLooping()
    }

    private func updateWorldVelocity(speed: CGFloat) {
        let velocity = CGVector(dx: -speed, dy: 0)

        // Update all moving entities
        for entity in activeEntities {
            // (This would be optimized with entity references)
        }

        // Update obstacle/coin velocities via their locomotion components
        for component in systemManager.locomotionSystem.components {
            if let linearStrategy = component.movementStrategy as? LinearMovementStrategy {
                linearStrategy.setVelocity(velocity)
            }
        }

        // Update background layer velocities
        for element in backgroundElements {
            if let locomotion = element.component(ofType: LocomotionComponent.self),
               let strategy = locomotion.movementStrategy as? LinearMovementStrategy {
                let layerMultiplier: CGFloat = {
                    if element.renderNode?.parent === farLayer { return 0.1 }
                    if element.renderNode?.parent === midLayer { return 0.5 }
                    return 1.2
                }()
                strategy.setVelocity(CGVector(dx: -speed * layerMultiplier, dy: 0))
            }
        }
    }

    private func checkAndSpawnChunks() {
        guard let player = playerEntity.renderNode else { return }

        // Spawn new chunk when player approaches the spawn point
        if player.position.x + size.width > nextChunkSpawnX {
            Task {
                let chunkData = await levelGenerator.generateNextChunk(
                    screenWidth: size.width,
                    distance: gameManager?.distance ?? 0
                )

                await MainActor.run {
                    spawnChunk(chunkData)
                }
            }
        }
    }

    private func spawnChunk(_ chunk: ChunkData) {
        // Spawn obstacles
        for obstacleData in chunk.obstacles {
            let obstacle = obstaclePool.spawn()

            // Recreate with correct type if needed (pool optimization)
            if let renderComp = obstacle.component(ofType: RenderComponent.self) {
                obstacle.position = CGPoint(x: obstacleData.relativeX, y: obstacleData.y)
                gameLayer.addChild(renderComp.node)
            }

            // Setup lifecycle callback
            if let lifecycle = obstacle.component(ofType: LifeCycleComponent.self) {
                lifecycle.onOffscreenCallback = { [weak self] entity in
                    self?.despawnEntity(entity as! GameEntity)
                }
            }

            systemManager.registerEntity(obstacle)
            activeEntities.insert(ObjectIdentifier(obstacle))
        }

        // Spawn coins
        for coinData in chunk.coins {
            let coin = coinPool.spawn()

            if let renderComp = coin.component(ofType: RenderComponent.self) {
                coin.position = CGPoint(x: coinData.relativeX, y: coinData.y)
                gameLayer.addChild(renderComp.node)
            }

            if let lifecycle = coin.component(ofType: LifeCycleComponent.self) {
                lifecycle.onOffscreenCallback = { [weak self] entity in
                    self?.despawnEntity(entity as! GameEntity)
                }
            }

            systemManager.registerEntity(coin)
            activeEntities.insert(ObjectIdentifier(coin))
        }

        nextChunkSpawnX = chunk.startX + chunk.length
    }

    private func despawnEntity(_ entity: GameEntity) {
        systemManager.unregisterEntity(entity)
        activeEntities.remove(ObjectIdentifier(entity))

        switch entity.entityType {
        case .obstacle:
            obstaclePool.despawn(entity)
        case .coin:
            coinPool.despawn(entity)
        default:
            break
        }
    }

    private func updateBackgroundLooping() {
        // Loop background elements that move off-screen
        for element in backgroundElements {
            guard let node = element.renderNode else { continue }

            if node.position.x < -100 {
                node.position.x += size.width + 200
            }
        }
    }

    // MARK: - Input Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameManager?.isJumpPressed = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameManager?.isJumpPressed = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        gameManager?.isJumpPressed = false
    }

    // MARK: - Public Control

    func resetGame() {
        // Clean up all entities
        for entity in activeEntities {
            // Despawn logic
        }
        activeEntities.removeAll()

        obstaclePool.despawnAll()
        coinPool.despawnAll()

        Task {
            await levelGenerator.reset()
        }

        nextChunkSpawnX = 800

        // Reset player position
        if let locomotion = playerEntity.component(ofType: JumpableLocomotionComponent.self) {
            locomotion.resetJumps()
        }
    }
}

// MARK: - Physics Contact Delegate

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        // Player + Obstacle
        if collision == (PhysicsCategory.player | PhysicsCategory.obstacle) {
            handlePlayerObstacleCollision()
        }

        // Player + Coin
        if collision == (PhysicsCategory.player | PhysicsCategory.coin) {
            handlePlayerCoinCollision(contact)
        }

        // Player + Ground (landing detection)
        if collision == (PhysicsCategory.player | PhysicsCategory.ground) {
            if let locomotion = playerEntity.component(ofType: JumpableLocomotionComponent.self) {
                locomotion.land()
            }
        }
    }

    private func handlePlayerObstacleCollision() {
        gameManager?.takeDamage()

        // Optional: Flash effect or knockback
    }

    private func handlePlayerCoinCollision(_ contact: SKPhysicsContact) {
        let coinBody = contact.bodyA.categoryBitMask == PhysicsCategory.coin ? contact.bodyA : contact.bodyB

        // Find entity and despawn
        // (Simplified - would need entity lookup)
        coinBody.node?.removeFromParent()

        gameManager?.addScore(10)
    }
}
