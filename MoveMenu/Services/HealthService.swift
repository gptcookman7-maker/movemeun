import Foundation
import HealthKit
import Observation

struct HealthSnapshot: Sendable {
    var activeKcal: Double?
    var steps: Double?
    var exerciseMinutes: Double?
    var syncedAt: Date
}

@MainActor @Observable
final class HealthService {
    private let store = HKHealthStore()
    private(set) var isLoading = false
    var status = "连接后，读取所选日期的活动热量、步数和运动分钟。"
    var available: Bool { HKHealthStore.isHealthDataAvailable() }

    func sync(date: Date) async throws -> HealthSnapshot {
        guard available else {
            throw NSError(domain: "MoveMenu", code: 1, userInfo: [NSLocalizedDescriptionKey: "此设备不支持 Apple 健康，请使用手动记录。"])
        }
        isLoading = true
        defer { isLoading = false }
        let types: Set<HKObjectType> = [
            HKQuantityType(.activeEnergyBurned), HKQuantityType(.stepCount), HKQuantityType(.appleExerciseTime)
        ]
        // Read-only. A successful request means the permission flow completed, not that access was granted.
        try await store.requestAuthorization(toShare: [], read: types)
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: start) else {
            throw PlannerError.invalidActivity
        }
        let end = min(tomorrow, Date())
        guard end > start else { throw PlannerError.missingHealthData }
        // Sequential queries make cancellation and error handling predictable for this small read.
        let energy = try await sum(.activeEnergyBurned, unit: .kilocalorie(), start: start, end: end)
        let steps = try await sum(.stepCount, unit: .count(), start: start, end: end)
        let minutes = try await sum(.appleExerciseTime, unit: .minute(), start: start, end: end)
        status = energy == nil
            ? "未读到活动热量：可能没有记录或读取未获授权。你仍可手动记录。"
            : "已读取活动热量。今日数据会随设备记录更新，可再次同步。"
        return HealthSnapshot(activeKcal: energy, steps: steps, exerciseMinutes: minutes, syncedAt: Date())
    }

    private func sum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async throws -> Double? {
        let type = HKQuantityType(identifier)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                           options: .cumulativeSum) { _, result, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: unit)) }
            }
            store.execute(query)
        }
    }
}
