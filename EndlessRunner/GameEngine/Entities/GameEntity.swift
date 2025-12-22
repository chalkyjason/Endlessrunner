import GameplayKit
import SpriteKit

/// Base GameEntity - Composition-based architecture
/// Entities are generic containers that gain capabilities through components
class GameEntity: GKEntity, Poolable {
    var entityType: EntityType = .obstacle

    // MARK: - Poolable Protocol

    func onSpawn() {
        // Activate all components
        if let lifecycle = component(ofType: LifeCycleComponent.self) {
            lifecycle.activate()
        }

        if let render = component(ofType: RenderComponent.self) {
            render.show()
        }
    }

    func onDespawn() {
        // Deactivate and reset
        if let lifecycle = component(ofType: LifeCycleComponent.self) {
            lifecycle.deactivate()
        }

        if let render = component(ofType: RenderComponent.self) {
            render.hide()
            render.node.removeFromParent()
        }

        if let physics = component(ofType: PhysicsComponent.self) {
            physics.physicsBody.velocity = .zero
        }

        if let locomotion = component(ofType: LocomotionComponent.self) {
            locomotion.movementStrategy.reset()
        }
    }

    // MARK: - Convenience Accessors

    var renderNode: SKNode? {
        // Try SpriteRenderComponent first (most common), then fall back to base RenderComponent
        if let spriteComp = component(ofType: SpriteRenderComponent.self) {
            return spriteComp.node
        }
        return component(ofType: RenderComponent.self)?.node
    }

    var position: CGPoint {
        get { renderNode?.position ?? .zero }
        set { renderNode?.position = newValue }
    }
}

// MARK: - Entity Type

enum EntityType {
    case player
    case obstacle
    case coin
    case powerup
    case background
}
