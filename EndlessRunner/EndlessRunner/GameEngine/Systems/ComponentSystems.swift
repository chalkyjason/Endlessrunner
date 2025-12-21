import GameplayKit
import SpriteKit

/// ComponentSystem - Deterministic update ordering for ECS
/// Prevents frame-lag by processing in explicit order

// MARK: - Input System

class InputSystem: GKComponentSystem<InputComponent> {
    override init() {
        super.init(componentClass: InputComponent.self)
    }
}

// MARK: - Locomotion System

class LocomotionSystem: GKComponentSystem<LocomotionComponent> {
    override init() {
        super.init(componentClass: LocomotionComponent.self)
    }
}

// MARK: - Lifecycle System

class LifeCycleSystem: GKComponentSystem<LifeCycleComponent> {
    override init() {
        super.init(componentClass: LifeCycleComponent.self)
    }
}

// MARK: - System Manager (Update Coordinator)

@MainActor
class SystemManager {
    let inputSystem = InputSystem()
    let locomotionSystem = LocomotionSystem()
    let lifecycleSystem = LifeCycleSystem()

    func update(deltaTime: TimeInterval) {
        // Explicit ordering prevents temporal artifacts
        // 1. Process input first
        inputSystem.update(deltaTime: deltaTime)

        // 2. Calculate movement
        locomotionSystem.update(deltaTime: deltaTime)

        // 3. Check lifecycle events
        lifecycleSystem.update(deltaTime: deltaTime)
    }

    func registerEntity(_ entity: GKEntity) {
        if let input = entity.component(ofType: InputComponent.self) {
            inputSystem.addComponent(input)
        }

        if let locomotion = entity.component(ofType: LocomotionComponent.self) {
            locomotionSystem.addComponent(locomotion)
        }

        if let lifecycle = entity.component(ofType: LifeCycleComponent.self) {
            lifecycleSystem.addComponent(lifecycle)
        }
    }

    func unregisterEntity(_ entity: GKEntity) {
        if let input = entity.component(ofType: InputComponent.self) {
            inputSystem.removeComponent(input)
        }

        if let locomotion = entity.component(ofType: LocomotionComponent.self) {
            locomotionSystem.removeComponent(locomotion)
        }

        if let lifecycle = entity.component(ofType: LifeCycleComponent.self) {
            lifecycleSystem.removeComponent(lifecycle)
        }
    }
}
