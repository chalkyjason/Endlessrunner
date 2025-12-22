import SpriteKit

/// Singleton Texture Manager - Runtime Rasterization and Caching Pipeline
/// Converts vector shapes to cached textures for optimal performance
/// Note: Texture generation can happen on any thread, but cache access is synchronized
class ShapeTextureManager {
    static let shared = ShapeTextureManager()

    private var cache: [String: SKTexture] = [:]
    private let defaultSize: CGSize = CGSize(width: 64, height: 64)
    private let cacheLock = NSLock()

    private init() {}

    // MARK: - Public API

    func texture(for shapeType: ShapeType, color: SKColor, size: CGSize? = nil) -> SKTexture {
        let actualSize = size ?? defaultSize
        let key = cacheKey(shapeType: shapeType, color: color, size: actualSize)

        cacheLock.lock()
        if let cached = cache[key] {
            cacheLock.unlock()
            return cached
        }
        cacheLock.unlock()

        let texture = generateTexture(shapeType: shapeType, color: color, size: actualSize)

        cacheLock.lock()
        cache[key] = texture
        cacheLock.unlock()

        return texture
    }

    func clearCache() {
        cacheLock.lock()
        cache.removeAll()
        cacheLock.unlock()
    }

    // MARK: - Private Helpers

    private func cacheKey(shapeType: ShapeType, color: SKColor, size: CGSize) -> String {
        return "\(shapeType.rawValue)_\(color.hexString)_\(Int(size.width))x\(Int(size.height))"
    }

    private func generateTexture(shapeType: ShapeType, color: SKColor, size: CGSize) -> SKTexture {
        let shapeNode = createShapeNode(type: shapeType, color: color, size: size)

        // Critical Performance Optimization: Render shape to texture once
        // This eliminates per-frame CPU rasterization
        let texture = SKView().texture(from: shapeNode) ?? SKTexture()
        texture.filteringMode = .nearest  // Crisp pixel art look

        return texture
    }

    private func createShapeNode(type: ShapeType, color: SKColor, size: CGSize) -> SKShapeNode {
        let path: UIBezierPath

        switch type {
        case .square:
            path = UIBezierPath(rect: CGRect(x: -size.width/2, y: -size.height/2,
                                             width: size.width, height: size.height))

        case .circle:
            path = UIBezierPath(ovalIn: CGRect(x: -size.width/2, y: -size.height/2,
                                               width: size.width, height: size.height))

        case .triangle:
            path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: size.height/2))
            path.addLine(to: CGPoint(x: -size.width/2, y: -size.height/2))
            path.addLine(to: CGPoint(x: size.width/2, y: -size.height/2))
            path.close()

        case .diamond:
            path = UIBezierPath()
            path.move(to: CGPoint(x: 0, y: size.height/2))
            path.addLine(to: CGPoint(x: -size.width/2, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -size.height/2))
            path.addLine(to: CGPoint(x: size.width/2, y: 0))
            path.close()

        case .hexagon:
            path = createHexagonPath(size: size)

        case .star:
            path = createStarPath(size: size, points: 5)
        }

        let shape = SKShapeNode(path: path.cgPath)
        shape.fillColor = color
        shape.strokeColor = color.withAlphaComponent(0.8)
        shape.lineWidth = 2.0
        shape.isAntialiased = true

        return shape
    }

    private func createHexagonPath(size: CGSize) -> UIBezierPath {
        let path = UIBezierPath()
        let radius = min(size.width, size.height) / 2

        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3.0
            let x = radius * cos(angle)
            let y = radius * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.close()
        return path
    }

    private func createStarPath(size: CGSize, points: Int) -> UIBezierPath {
        let path = UIBezierPath()
        let radius = min(size.width, size.height) / 2
        let innerRadius = radius * 0.4

        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let currentRadius = i % 2 == 0 ? radius : innerRadius
            let x = currentRadius * cos(angle)
            let y = currentRadius * sin(angle)

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.close()
        return path
    }
}

// MARK: - Shape Type Enum

enum ShapeType: String {
    case square
    case circle
    case triangle
    case diamond
    case hexagon
    case star
}

// MARK: - SKColor Extension (Hex String for Caching)

extension SKColor {
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X%02X",
                     Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
    }
}
