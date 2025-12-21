import GameplayKit
import SpriteKit

/// LifeCycleComponent - Manages entity pooling and cleanup
/// Critical for endless memory management
class LifeCycleComponent: GKComponent {
    weak var renderComponent: RenderComponent?

    var offscreenThreshold: CGFloat = -200.0  // Left edge of screen
    var isActive: Bool = true

    var onOffscreenCallback: ((GKEntity) -> Void)?

    init(offscreenThreshold: CGFloat = -200.0) {
        self.offscreenThreshold = offscreenThreshold
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didAddToEntity() {
        super.didAddToEntity()
        renderComponent = entity?.component(ofType: RenderComponent.self)
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        guard isActive, let node = renderComponent?.node else { return }

        // Check if off-screen (left side for side-scroller)
        if node.position.x < offscreenThreshold {
            markForDespawn()
        }
    }

    func markForDespawn() {
        guard let entity = entity else { return }
        isActive = false
        onOffscreenCallback?(entity)
    }

    func activate() {
        isActive = true
    }

    func deactivate() {
        isActive = false
    }
}
