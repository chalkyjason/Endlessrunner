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
    private var entitiesToDespawn: [GameEntity] = []  // Defer despawn to avoid mutation-while-iterating

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

        // Spawn initial chunks so player sees obstacles immediately
        spawnInitialChunks()
    }

    private func spawnInitialChunks() {
        // Spawn 3 initial chunks to fill the screen
        Task {
            for _ in 0..<3 {
                let chunkData = await levelGenerator.generateNextChunk(
                    screenWidth: size.width,
                    distance: 0
                )
                await MainActor.run {
                    spawnChunk(chunkData)
                }
            }
        }
    }

    private func setupScene() {
        backgroundColor = SKColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        anchorPoint = CGPoint(x: 0, y: 0)
        
        // Debug: Log scene setup
        print("🎮 GameScene initialized - Size: \(size)")
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
        
        // Debug: Log layer setup
        print("📐 Layers created - gameLayer children: \(gameLayer.children.count)")
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
        groundBody.contactTestBitMask = PhysicsCategory.player  // Enable contact detection
        groundNode.physicsBody = groundBody

        gameLayer.addChild(groundNode)

        // Debug: Log ground setup
        print("✅ Ground created at y: \(groundHeight / 2), height: \(groundHeight)")
    }

    private func setupPlayer() {
        playerEntity = entityFactory.createPlayer()

        // CRITICAL: Add render node to scene
        guard let renderNode = playerEntity.renderNode else {
            print("❌ ERROR: Player has no render node!")
            return
        }

        // Position: Fixed at 20% from left edge, ON THE GROUND
        let playerX = size.width * 0.2
        // Player sits on ground: groundHeight (80) + half player height (20) = 100
        let playerY = groundHeight + 20
        renderNode.position = CGPoint(x: playerX, y: playerY)
        renderNode.zPosition = 10  // Ensure player is above ground

        // Add to scene
        gameLayer.addChild(renderNode)

        // Add particle trail for visual flair (Geometry Dash style!)
        let trail = ParticleFactory.createPlayerTrail()
        renderNode.addChild(trail)

        // Register with systems AFTER node is added
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

        // Initialize lastUpdateTime on first frame to prevent huge deltaTime
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }

        let deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        // Debug: Track player position every 60 frames (once per second at 60fps)
        if Int(currentTime * 60) % 60 == 0 {
            if let playerNode = playerEntity.renderNode {
                print("🎮 Player pos: \(playerNode.position), velocity: \(playerNode.physicsBody?.velocity ?? .zero)")
            }
        }

        // Update game speed
        manager.updateSpeed(deltaTime)
        // Convert pixels per second to meters (divide by 100 pixels = 1 meter)
        manager.updateDistance(Double(manager.currentSpeed) * deltaTime / 100.0)

        // Update world velocity based on current speed
        updateWorldVelocity(speed: manager.currentSpeed)

        // Update all ECS systems
        systemManager.update(deltaTime: deltaTime)

        // Apply velocity-based scaling to player (visual feedback)
        updatePlayerScale()

        // Process deferred despawns (after iteration completes to avoid mutation-while-iterating crash)
        processPendingDespawns()

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

    private func updatePlayerScale() {
        guard let playerNode = playerEntity.renderNode,
              let velocity = playerNode.physicsBody?.velocity,
              let sprite = playerNode as? SKSpriteNode else { return }

        // Scale width based on Y velocity (faster = wider)
        // Falling: negative velocity -> wider (up to 1.5x)
        // Rising: positive velocity -> narrower (down to 0.8x)
        let maxFallSpeed: CGFloat = 800  // Terminal velocity
        let maxRiseSpeed: CGFloat = 1000  // Jump impulse

        let velocityRatio: CGFloat
        if velocity.dy < 0 {
            // Falling - get wider
            velocityRatio = min(abs(velocity.dy) / maxFallSpeed, 1.0)
            playerNode.xScale = 1.0 + (velocityRatio * 0.5)  // 1.0 to 1.5
        } else {
            // Rising - get narrower
            velocityRatio = min(velocity.dy / maxRiseSpeed, 1.0)
            playerNode.xScale = 1.0 - (velocityRatio * 0.2)  // 1.0 to 0.8
        }

        // Keep Y scale constant (height doesn't change)
        playerNode.yScale = 1.0

        // Geometry Dash style: Color shifts with game speed!
        if let manager = gameManager {
            let speedRatio = (manager.currentSpeed - manager.baseSpeed) / (manager.maxSpeed - manager.baseSpeed)

            // Cyan -> Magenta -> Yellow as speed increases
            if speedRatio < 0.5 {
                // Cyan to Magenta
                let t = speedRatio * 2.0
                sprite.color = SKColor(
                    red: t,
                    green: 1.0 - t,
                    blue: 1.0,
                    alpha: 1.0
                )
            } else {
                // Magenta to Yellow
                let t = (speedRatio - 0.5) * 2.0
                sprite.color = SKColor(
                    red: 1.0,
                    green: t,
                    blue: 1.0 - t,
                    alpha: 1.0
                )
            }
            sprite.colorBlendFactor = 1.0
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
        print("🎯 SPAWNING CHUNK: \(chunk.obstacles.count) obstacles, \(chunk.coins.count) coins")

        // Spawn obstacles
        for obstacleData in chunk.obstacles {
            let obstacle = obstaclePool.spawn()

            // Use renderNode property (handles SpriteRenderComponent correctly)
            if let node = obstacle.renderNode {
                obstacle.position = CGPoint(x: obstacleData.relativeX, y: obstacleData.y)
                node.zPosition = 5  // Ensure obstacles visible

                // Safety check: only add if not already in scene tree
                if node.parent == nil {
                    gameLayer.addChild(node)

                    // Geometry Dash style: Rotate obstacles continuously!
                    let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
                    let repeatRotate = SKAction.repeatForever(rotateAction)
                    node.run(repeatRotate, withKey: "obstacleRotation")
                }
                print("  ⚠️ OBSTACLE at x:\(obstacleData.relativeX), y:\(obstacleData.y)")
            }

            // Setup lifecycle callback - defer despawn to avoid mutation-while-iterating
            if let lifecycle = obstacle.component(ofType: LifeCycleComponent.self) {
                lifecycle.onOffscreenCallback = { [weak self] entity in
                    guard let self = self, let gameEntity = entity as? GameEntity else { return }
                    self.entitiesToDespawn.append(gameEntity)
                }
            }

            systemManager.registerEntity(obstacle)
            activeEntities.insert(ObjectIdentifier(obstacle))
        }

        // Spawn coins
        for coinData in chunk.coins {
            let coin = coinPool.spawn()

            // Use renderNode property (handles SpriteRenderComponent correctly)
            if let node = coin.renderNode {
                coin.position = CGPoint(x: coinData.relativeX, y: coinData.y)
                node.zPosition = 5

                // Safety check: only add if not already in scene tree
                if node.parent == nil {
                    gameLayer.addChild(node)

                    // Geometry Dash style: Coins pulse and rotate!
                    let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
                    let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
                    let pulse = SKAction.sequence([scaleUp, scaleDown])
                    let repeatPulse = SKAction.repeatForever(pulse)
                    node.run(repeatPulse, withKey: "coinPulse")

                    // Rotate slowly
                    let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: 3.0)
                    let repeatRotate = SKAction.repeatForever(rotateAction)
                    node.run(repeatRotate, withKey: "coinRotation")
                }
                print("  💰 COIN at x:\(coinData.relativeX), y:\(coinData.y)")
            }

            // Setup lifecycle callback - defer despawn to avoid mutation-while-iterating
            if let lifecycle = coin.component(ofType: LifeCycleComponent.self) {
                lifecycle.onOffscreenCallback = { [weak self] entity in
                    guard let self = self, let gameEntity = entity as? GameEntity else { return }
                    self.entitiesToDespawn.append(gameEntity)
                }
            }

            systemManager.registerEntity(coin)
            activeEntities.insert(ObjectIdentifier(coin))
        }

        nextChunkSpawnX = chunk.startX + chunk.length
    }

    private func processPendingDespawns() {
        // Process all entities marked for despawn during the update loop
        // This avoids mutation-while-iterating crashes
        for entity in entitiesToDespawn {
            despawnEntity(entity)
        }
        entitiesToDespawn.removeAll(keepingCapacity: true)  // Keep capacity for performance
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
        for _ in activeEntities {
            // Despawn logic
        }
        activeEntities.removeAll()

        obstaclePool.despawnAll()
        coinPool.despawnAll()

        Task {
            await levelGenerator.reset()
        }

        nextChunkSpawnX = 800

        // Reset player position and state
        if let renderNode = playerEntity.renderNode {
            let playerX = size.width * 0.2
            let playerY = groundHeight + 50
            renderNode.position = CGPoint(x: playerX, y: playerY)
            
            // Reset physics
            if let physicsBody = renderNode.physicsBody {
                physicsBody.velocity = .zero
                physicsBody.angularVelocity = 0
            }
        }
        
        if let locomotion = playerEntity.component(ofType: JumpableLocomotionComponent.self) {
            locomotion.resetJumps()
        }
        
        print("🔄 Game reset - Player repositioned")
    }
}

// MARK: - Physics Contact Delegate

extension GameScene: SKPhysicsContactDelegate {
    nonisolated func didBegin(_ contact: SKPhysicsContact) {
        // Schedule on main actor since we're accessing @MainActor isolated properties
        MainActor.assumeIsolated {
            handleContactOnMainActor(contact)
        }
    }

    private func handleContactOnMainActor(_ contact: SKPhysicsContact) {
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

                // Landing explosion effect!
                if let playerNode = playerEntity.renderNode {
                    let explosion = ParticleFactory.createLandingExplosion(at: playerNode.position)
                    gameLayer.addChild(explosion)

                    // Remove emitter after particles are done
                    let wait = SKAction.wait(forDuration: 0.5)
                    let remove = SKAction.removeFromParent()
                    explosion.run(SKAction.sequence([wait, remove]))
                }
            }
        }
    }

    private func handlePlayerObstacleCollision() {
        gameManager?.takeDamage()

        // Death explosion if health runs out
        if let manager = gameManager, manager.health <= 0 {
            if let playerNode = playerEntity.renderNode {
                let explosion = ParticleFactory.createDeathExplosion(color: .cyan)
                explosion.position = playerNode.position
                gameLayer.addChild(explosion)

                // Remove after explosion
                let wait = SKAction.wait(forDuration: 0.7)
                let remove = SKAction.removeFromParent()
                explosion.run(SKAction.sequence([wait, remove]))
            }
        }
    }

    private func handlePlayerCoinCollision(_ contact: SKPhysicsContact) {
        let coinBody = contact.bodyA.categoryBitMask == PhysicsCategory.coin ? contact.bodyA : contact.bodyB

        // Coin sparkle effect!
        if let coinNode = coinBody.node {
            let sparkle = ParticleFactory.createCoinSparkle(at: coinNode.position)
            gameLayer.addChild(sparkle)

            // Remove sparkle after done
            let wait = SKAction.wait(forDuration: 0.4)
            let remove = SKAction.removeFromParent()
            sparkle.run(SKAction.sequence([wait, remove]))
        }

        // Find entity and despawn
        coinBody.node?.removeFromParent()

        gameManager?.addScore(10)
    }
}

