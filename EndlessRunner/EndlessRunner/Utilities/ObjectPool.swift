import GameplayKit

/// Generic Object Pool - Prevents memory allocation stuttering
/// Critical for maintaining 60fps in endless gameplay
@MainActor
class ObjectPool<T: Poolable> {
    private var inactive: [T] = []
    private var active: Set<ObjectIdentifier> = []

    private let createInstance: () -> T
    private let minPoolSize: Int

    init(minPoolSize: Int = 20, createInstance: @escaping () -> T) {
        self.minPoolSize = minPoolSize
        self.createInstance = createInstance

        // Pre-populate pool to avoid first-frame allocations
        prewarmPool()
    }

    // MARK: - Pool Operations

    func spawn() -> T {
        let instance: T

        if let reused = inactive.popLast() {
            instance = reused
        } else {
            instance = createInstance()
        }

        active.insert(ObjectIdentifier(instance as AnyObject))
        instance.onSpawn()
        return instance
    }

    func despawn(_ instance: T) {
        let id = ObjectIdentifier(instance as AnyObject)
        guard active.contains(id) else { return }

        active.remove(id)
        instance.onDespawn()
        inactive.append(instance)
    }

    func despawnAll() {
        // Move all active instances back to inactive pool
        inactive.removeAll()
        active.removeAll()
    }

    // MARK: - Pool Management

    private func prewarmPool() {
        for _ in 0..<minPoolSize {
            let instance = createInstance()
            instance.onDespawn()
            inactive.append(instance)
        }
    }

    func maintainMinimumSize() {
        let deficit = minPoolSize - inactive.count
        if deficit > 0 {
            for _ in 0..<deficit {
                let instance = createInstance()
                instance.onDespawn()
                inactive.append(instance)
            }
        }
    }

    // MARK: - Pool Stats

    var poolStats: PoolStats {
        return PoolStats(active: active.count, inactive: inactive.count, total: active.count + inactive.count)
    }
}

// MARK: - Poolable Protocol

protocol Poolable: AnyObject {
    func onSpawn()
    func onDespawn()
}

// MARK: - Pool Stats

struct PoolStats {
    let active: Int
    let inactive: Int
    let total: Int
}
