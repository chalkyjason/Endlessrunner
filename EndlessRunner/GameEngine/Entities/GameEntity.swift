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
        let comp = component(ofType: RenderComponent.self)
        print("🔍 renderNode getter - Has component: \(comp != nil)")
        if comp == nil {
            print("   ❌ NO RENDER COMPONENT!")
            print("   Entity has \(components.count) components:")
            for c in components {
                print("      - \(type(of: c))")
            }
        }
        return comp?.node
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
