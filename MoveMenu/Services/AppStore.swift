import Foundation
import SwiftUI

struct SavedState: Codable {
    var schemaVersion = 1
    var profile = Profile()
    var days: [String: DailyActivity] = [:]
    var variations: [String: [String: Int]] = [:]
}

@MainActor @Observable
final class AppStore {
    private(set) var state = SavedState()
    private(set) var dataEpoch = UUID()
    var selectedDate = Date()
    var message: String?
    private let fileURL: URL?
    private var storageWritable = true
    private let inMemory: Bool

    init(inMemory: Bool = false) {
        self.inMemory = inMemory
        if inMemory { fileURL = nil; return }
        do {
            let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                        appropriateFor: nil, create: true)
                .appendingPathComponent("MoveMenu", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var excludedDirectory = directory
            var backupValues = URLResourceValues()
            backupValues.isExcludedFromBackup = true
            try excludedDirectory.setResourceValues(backupValues)
            fileURL = directory.appendingPathComponent("state.json")
        } catch {
            fileURL = nil
            message = "暂时无法建立本地存储，本次更改可能无法保留。"
            return
        }
        if let fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let loaded = try JSONDecoder().decode(SavedState.self, from: Data(contentsOf: fileURL))
                guard loaded.schemaVersion == 1 else {
                    storageWritable = false
                    message = "本地数据版本较新，请使用匹配的应用版本。"
                    return
                }
                state = loaded
            } catch {
                storageWritable = false
                message = "本地记录读取失败，已暂停写入以保留原文件。可在“我的”删除本机记录后重新开始。"
            }
        }
    }

    var profile: Profile { state.profile }
    var day: String { DayKey.make(selectedDate) }
    var activity: DailyActivity { state.days[day] ?? DailyActivity() }
    var plan: Result<MenuPlan, Error> {
        Result { try Planner.make(profile: state.profile, activity: activity, day: day,
                                  variations: state.variations[day] ?? [:]) }
    }

    func saveProfile(_ value: Profile) {
        state.profile = value
        persist()
    }

    func updateActivity(_ transform: (inout DailyActivity) -> Void) {
        let key = day
        var value = state.days[key] ?? DailyActivity()
        transform(&value)
        state.days[key] = value
        persist()
    }

    func applyHealth(_ snapshot: HealthSnapshot, day key: String, epoch: UUID) {
        // A pending query must not recreate records after the user deletes their data.
        guard epoch == dataEpoch else { return }
        var value = state.days[key] ?? DailyActivity()
        value.healthActiveKcal = snapshot.activeKcal
        value.healthSteps = snapshot.steps
        value.healthExerciseMinutes = snapshot.exerciseMinutes
        value.syncedAt = snapshot.syncedAt
        // An empty result does not prove denial and must not erase a usable manual mode.
        if snapshot.activeKcal != nil { value.source = .healthKit }
        state.days[key] = value
        persist()
    }

    func swap(_ slot: MealSlot) {
        var rotations = state.variations[day] ?? [:]
        rotations[slot.rawValue, default: 0] += 1
        state.variations[day] = rotations
        persist()
    }

    func eraseAll() {
        do {
            if let fileURL, FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            state = SavedState()
            dataEpoch = UUID()
            storageWritable = true
            selectedDate = Date()
        } catch { message = "本地记录未能删除，请重试。" }
    }

    private func persist() {
        if inMemory { return }
        guard storageWritable else {
            message = "为保护未能读取的原记录，本次更改没有保存。请在“我的”删除本机记录后重试。"
            return
        }
        guard let fileURL else { message = "本次更改仅保留到应用关闭。"; return }
        do {
            let bytes = try JSONEncoder().encode(state)
            try bytes.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch { message = "保存失败，本次更改尚未写入设备。" }
    }

    static var preview: AppStore {
        let store = AppStore(inMemory: true)
        store.state.profile = Profile(name: "示例用户", age: 30, formulaSex: .male, heightCM: 175,
                                      weightKG: 70, goal: .maintain, completed: true)
        var day = DailyActivity()
        day.workouts = [Workout(kind: .jogging, minutes: 35)]
        store.state.days[DayKey.make(Date())] = day
        return store
    }
}
