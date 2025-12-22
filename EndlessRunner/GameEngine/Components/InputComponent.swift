import GameplayKit
import SpriteKit

/// InputComponent - Maps GameManager input states to entity actions
/// Moderate reusability: Specific to player-controlled entities
@MainActor
class InputComponent: GKComponent {
    weak var gameManager: GameManager?
    weak var locomotionComponent: JumpableLocomotionComponent?

    private var wasJumpPressed: Bool = false

    init(gameManager: GameManager) {
        self.gameManager = gameManager
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didAddToEntity() {
        super.didAddToEntity()
        locomotionComponent = entity?.component(ofType: JumpableLocomotionComponent.self)
    }

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)

        guard let manager = gameManager,
              let locomotion = locomotionComponent else { return }

        // Jump detection (edge-triggered, not level-triggered)
        if manager.isJumpPressed && !wasJumpPressed {
            locomotion.jump()
        }
        wasJumpPressed = manager.isJumpPressed

        // Slide detection (future implementation)
        // if manager.isSlidePressed { ... }
    }
}
