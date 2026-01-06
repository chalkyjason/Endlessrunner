import SpriteKit

/// ParticleFactory - Creates particle emitters for visual effects
/// Uses SpriteKit's built-in SKEmitterNode - no external packages needed!
@MainActor
class ParticleFactory {

    // MARK: - Player Trail Effect

    static func createPlayerTrail() -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Particle appearance
        emitter.particleTexture = SKTexture(imageNamed: "spark") // Will use colored rectangle
        emitter.particleColor = .cyan
        emitter.particleColorBlendFactor = 1.0
        emitter.particleColorSequence = nil

        // Size animation: start medium, fade to tiny
        emitter.particleSize = CGSize(width: 8, height: 8)
        emitter.particleScaleSpeed = -0.5  // Shrink over time

        // Emission
        emitter.particleBirthRate = 100  // Lots of particles!
        emitter.numParticlesToEmit = 0  // Continuous

        // Lifetime
        emitter.particleLifetime = 0.3  // Short trail
        emitter.particleLifetimeRange = 0.1

        // Motion - particles drift backward slightly
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 10
        emitter.emissionAngle = .pi  // Emit backward (180 degrees)
        emitter.emissionAngleRange = .pi / 6  // 30 degree spread

        // Alpha fade out
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -2.0  // Fade fast

        // Blend mode for glow effect
        emitter.particleBlendMode = .add

        // Position relative to parent (player)
        emitter.position = CGPoint(x: -10, y: 0)  // Behind player
        emitter.zPosition = -1  // Behind player sprite

        return emitter
    }

    // MARK: - Landing Explosion

    static func createLandingExplosion(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Particle appearance
        emitter.particleColor = .white
        emitter.particleColorBlendFactor = 1.0

        // Color sequence: white -> cyan -> transparent
        let colorSequence = SKKeyframeSequence(
            keyframeValues: [
                SKColor.white,
                SKColor.cyan,
                SKColor.cyan.withAlphaComponent(0)
            ],
            times: [0.0, 0.3, 1.0]
        )
        emitter.particleColorSequence = colorSequence

        // Size: start small, grow, then shrink
        emitter.particleSize = CGSize(width: 6, height: 6)
        emitter.particleScaleSpeed = 0.5
        emitter.particleScaleSequence = SKKeyframeSequence(
            keyframeValues: [0.0, 1.0, 0.0] as [NSNumber],
            times: [0.0, 0.3, 1.0]
        )

        // Burst emission
        emitter.particleBirthRate = 200
        emitter.numParticlesToEmit = 20  // Just a burst

        // Lifetime
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.1

        // Motion - explode outward
        emitter.particleSpeed = 150
        emitter.particleSpeedRange = 50
        emitter.emissionAngle = .pi / 2  // Up
        emitter.emissionAngleRange = .pi  // Full 180 degrees

        // Gravity pulls down
        emitter.xAcceleration = 0
        emitter.yAcceleration = -300

        // Position
        emitter.position = position
        emitter.zPosition = 5

        // Blend mode
        emitter.particleBlendMode = .add

        return emitter
    }

    // MARK: - Death Explosion

    static func createDeathExplosion(color: SKColor) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Particle appearance - uses player's current color
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1.0

        // Size
        emitter.particleSize = CGSize(width: 10, height: 10)
        emitter.particleScaleSpeed = -1.0

        // Massive burst!
        emitter.particleBirthRate = 500
        emitter.numParticlesToEmit = 50

        // Lifetime
        emitter.particleLifetime = 0.6
        emitter.particleLifetimeRange = 0.2

        // Motion - explode in all directions
        emitter.particleSpeed = 200
        emitter.particleSpeedRange = 100
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2  // Full 360

        // Spin particles
        emitter.particleRotation = 0
        emitter.particleRotationRange = .pi * 2
        emitter.particleRotationSpeed = 5

        // Alpha fade
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -1.5

        // Blend mode
        emitter.particleBlendMode = .add

        emitter.zPosition = 10

        return emitter
    }

    // MARK: - Coin Collection Sparkle

    static func createCoinSparkle(at position: CGPoint) -> SKEmitterNode {
        let emitter = SKEmitterNode()

        // Yellow sparkles
        emitter.particleColor = .yellow
        emitter.particleColorBlendFactor = 1.0

        // Size
        emitter.particleSize = CGSize(width: 4, height: 4)
        emitter.particleScaleSpeed = -0.5

        // Quick burst
        emitter.particleBirthRate = 100
        emitter.numParticlesToEmit = 15

        // Lifetime
        emitter.particleLifetime = 0.3

        // Motion - small explosion
        emitter.particleSpeed = 80
        emitter.particleSpeedRange = 40
        emitter.emissionAngle = 0
        emitter.emissionAngleRange = .pi * 2

        // Alpha fade
        emitter.particleAlpha = 1.0
        emitter.particleAlphaSpeed = -3.0

        // Position
        emitter.position = position
        emitter.zPosition = 5

        // Blend mode
        emitter.particleBlendMode = .add

        return emitter
    }
}
