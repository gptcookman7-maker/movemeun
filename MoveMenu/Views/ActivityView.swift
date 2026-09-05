import SwiftUI
import UIKit

struct ActivityView: View {
    @Environment(AppStore.self) private var store
    @Environment(HealthService.self) private var health
    @State private var addingWorkout = false
    @State private var choosingDate = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { choosingDate = true } label: {
                        LabeledContent("记录日期", value: store.selectedDate.formatted(date: .abbreviated, time: .omitted))
                    }
                    Picker("热量来源", selection: Binding(get: { store.activity.source }, set: { source in
                        store.updateActivity { $0.source = source }
                    })) {
                        ForEach(ActivitySource.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                } footer: { Text("一次只使用一种活动热量来源。步数用于展示，不会另加热量。") }

                if store.activity.source == .manual {
                    Section {
                        HStack {
                            Text("活动热量")
                            TextField("kcal", value: Binding(get: { store.activity.manualActiveKcal }, set: { value in
                                store.updateActivity { $0.manualActiveKcal = value }
                            }), format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .accessibilityLabel("手动活动热量，千卡")
                            Text("kcal").foregroundStyle(.secondary)
                        }
                    } header: { Text("手动记录") } footer: { Text("填写设备统计的全天活动热量，不要填写包含静息消耗的总热量。本版上限为 1,800 kcal。") }
                }

                if store.activity.source == .workouts {
                    Section {
                        if store.activity.workouts.isEmpty {
                            ContentUnavailableView("还没有运动记录", systemImage: "figure.walk",
                                                   description: Text("休息日也可以生成菜单。运动后，添加类型和时长即可。"))
                        }
                        ForEach(store.activity.workouts) { workout in
                            HStack(spacing: 14) {
                                Image(systemName: workout.kind.symbol).font(.title2).foregroundStyle(.teal).frame(width: 32)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(workout.kind.title).font(.headline)
                                    Text("\(workout.minutes.whole) 分钟 · 净消耗约 \(workout.netKcal(weightKG: store.profile.weightKG).whole) kcal")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                            }.padding(.vertical, 5)
                        }
                        .onDelete { indices in store.updateActivity { $0.workouts.remove(atOffsets: indices) } }
                        Button { addingWorkout = true } label: { Label("添加运动", systemImage: "plus") }
                    } header: { Text("所选日期的运动") } footer: {
                        Text("净消耗扣除了运动期间本来就有的静息消耗。另加的日常活动量是估计值；相同运动不要重复记录。")
                    }
                }

                Section {
                    Button {
                        let date = store.selectedDate
                        let day = DayKey.make(date)
                        let epoch = store.dataEpoch
                        Task {
                            do {
                                let result = try await health.sync(date: date)
                                store.applyHealth(result, day: day, epoch: epoch)
                            } catch { store.message = error.localizedDescription }
                        }
                    } label: {
                        HStack {
                            Label("同步 Apple 健康", systemImage: "heart.fill")
                            Spacer()
                            if health.isLoading { ProgressView() }
                        }.padding(.vertical, 4)
                    }
                    .disabled(health.isLoading || !health.available)
                    if let value = store.activity.healthActiveKcal {
                        LabeledContent("活动热量", value: "\(value.whole) kcal")
                    }
                    if let value = store.activity.healthSteps { LabeledContent("步数", value: value.whole) }
                    if let value = store.activity.healthExerciseMinutes { LabeledContent("运动时间", value: "\(value.whole) 分钟") }
                    if let date = store.activity.syncedAt {
                        LabeledContent("上次同步", value: date.formatted(date: .abbreviated, time: .shortened))
                    }
                } header: { Text("Apple 健康") } footer: {
                    Text(health.available ? health.status : "此设备不支持 Apple 健康，可以使用上方的手动记录。")
                }

                Section {
                    switch store.plan {
                    case .success(let plan):
                        LabeledContent("活动消耗估算", value: "\(plan.budget.active.whole) kcal")
                        LabeledContent("当前摄入目标", value: "\(plan.budget.target.whole) kcal")
                        Text("菜单份量已根据当前记录更新。").font(.subheadline).foregroundStyle(.teal)
                    case .failure(let error):
                        Text(error.localizedDescription).foregroundStyle(.secondary)
                    }
                } header: { Text("对菜单的影响") }
            }
            .navigationTitle("运动")
            .sheet(isPresented: $addingWorkout) { AddWorkoutView() }
            .sheet(isPresented: $choosingDate) { DateSelectionView() }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
        }
    }
}

struct AddWorkoutView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var kind: WorkoutKind = .walking
    @State private var minutes = 30.0
    var body: some View {
        NavigationStack {
            Form {
                Section("运动类型") {
                    Picker("类型", selection: $kind) {
                        ForEach(WorkoutKind.allCases, id: \.self) { Text($0.title).tag($0) }
                    }.pickerStyle(.inline).labelsHidden()
                }
                Section {
                    Stepper("\(minutes.whole) 分钟", value: $minutes, in: 5...180, step: 5)
                    LabeledContent("预计净消耗", value: "\(Workout(kind: kind, minutes: minutes).netKcal(weightKG: store.profile.weightKG).whole) kcal")
                } header: { Text("时长") } footer: { Text("强度取该类型的参考值，实际消耗因人而异。记录日期：\(store.selectedDate.formatted(date: .abbreviated, time: .omitted))。") }
            }
            .navigationTitle("添加运动").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        store.updateActivity { $0.workouts.append(Workout(kind: kind, minutes: minutes)) }
                        dismiss()
                    }.disabled(store.activity.workouts.reduce(0) { $0 + $1.minutes } + minutes > 360)
                }
            }
        }
    }
}
