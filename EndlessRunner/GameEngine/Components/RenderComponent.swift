import GameplayKit
import SpriteKit

/// RenderComponent - Wraps the SKNode for visual representation
/// High reusability: Works for Player, Enemy, Coin, Background
class RenderComponent: GKComponent {
    let node: SKNode

    init(node: SKNode) {
        self.node = node
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visual State Management

    func show() {
        node.isHidden = false
    }

    func hide() {
        node.isHidden = true
    }

    func setAlpha(_ alpha: CGFloat) {
        node.alpha = alpha
    }

    func setPosition(_ position: CGPoint) {
        node.position = position
    }

    func setZPosition(_ z: CGFloat) {
        node.zPosition = z
    }
}

// MARK: - Sprite-Specific RenderComponent

class SpriteRenderComponent: RenderComponent {
    var spriteNode: SKSpriteNode {
        return node as! SKSpriteNode
    }

    init(texture: SKTexture, size: CGSize) {
        let sprite = SKSpriteNode(texture: texture, size: size)
        super.init(node: sprite)
    }

    convenience init(shapeType: ShapeType, color: SKColor, size: CGSize) {
        // CRITICAL FIX: SKSpriteNode(color:size:) needs proper setup
        let sprite = SKSpriteNode(color: color, size: size)
        
        // This is the key - without this, colored sprites might not render!
        sprite.colorBlendFactor = 1.0
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)  // Center anchor
        
        print("🎨 Creating sprite: \(shapeType)")
        print("   Color: \(color)")
        print("   Size: \(size)")
        print("   Frame: \(sprite.frame)")
        
        // Initialize with the sprite node
        self.init(node: sprite)
    }
    
    // Alternative initializer for direct SKSpriteNode
    init(node: SKSpriteNode) {
        super.init(node: node)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTexture(_ texture: SKTexture) {
        spriteNode.texture = texture
    }
}
