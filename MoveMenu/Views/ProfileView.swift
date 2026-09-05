import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(AppStore.self) private var store
    @State private var editing = false
    @State private var confirmingErase = false
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill").font(.system(size: 48)).foregroundStyle(.teal)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(store.profile.name.isEmpty ? "我的档案" : store.profile.name).font(.title2.bold())
                            Text(store.profile.goal.title + " · " + store.profile.diet.title).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 12)
                    Button("编辑个人档案") { editing = true }
                }
                Section("当前设置") {
                    LabeledContent("年龄", value: "\(store.profile.age) 岁")
                    LabeledContent("身高", value: "\(store.profile.heightCM.whole) cm")
                    LabeledContent("体重", value: "\(store.profile.weightKG.formatted()) kg")
                    LabeledContent("过敏原排除", value: store.profile.allergens.isEmpty ? "未设置" : "\(store.profile.allergens.count) 类")
                    LabeledContent("不吃的食材", value: "\(store.profile.avoidedFoods.count) 种")
                }
                Section("隐私与数据") {
                    Label("记录保存在本机", systemImage: "iphone")
                    Text("本版无需账号，不上传个人档案或健康数据。应用数据不进入 iCloud 备份；换机或卸载可能丢失。Apple 健康只申请读取权限，不修改健康记录。")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("修改个人档案后，历史日期的菜单也会按新档案重新估算；它不是实际饮食日志。")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Button("删除本机全部记录", role: .destructive) { confirmingErase = true }
                }
                Section("关于动膳") {
                    LabeledContent("版本", value: "0.1.0 · 原生开发首版")
                    Text("为一般健康成人提供活动量相关的菜单参考。孕期、哺乳期、需治疗饮食或进食障碍等情况应单独评估。本版菜谱营养是示例估算，尚未经营养师审核。")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Link("能量公式参考", destination: URL(string: "https://pubmed.ncbi.nlm.nih.gov/2305711/")!)
                    Link("运动强度参考", destination: URL(string: "https://pacompendium.com/")!)
                }
            }
            .navigationTitle("我的")
            .sheet(isPresented: $editing) { ProfileEditor(initial: store.profile) }
            .confirmationDialog("删除档案、运动记录和换餐记录？此操作无法撤销。", isPresented: $confirmingErase, titleVisibility: .visible) {
                Button("删除全部记录", role: .destructive) { store.eraseAll() }
                Button("取消", role: .cancel) { }
            }
        }
    }
}

struct ProfileEditor: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Profile
    @State private var error: String?
    var onboarding: Bool

    init(initial: Profile, onboarding: Bool = false) {
        _draft = State(initialValue: initial)
        self.onboarding = onboarding
    }

    var body: some View {
        NavigationStack {
            Form {
                if onboarding {
                    Section {
                        VStack(alignment: .leading, spacing: 14) {
                            Image(systemName: "fork.knife.circle.fill").font(.system(size: 54)).foregroundStyle(.teal)
                            Text("让菜单，跟上你的节奏。").font(.title2.bold())
                            Text("先填写个人资料，再记录每天的运动。下面的数值是填写示例，请改成你的实际信息。")
                                .foregroundStyle(.secondary)
                        }.padding(.vertical, 12)
                    }
                }
                Section {
                    TextField("昵称（可选）", text: $draft.name).textContentType(.nickname)
                    numericRow("年龄", value: $draft.age, unit: "岁")
                    numericRow("身高", value: $draft.heightCM, unit: "cm")
                    numericRow("体重", value: $draft.weightKG, unit: "kg")
                    Picker("代谢估算参数", selection: $draft.formulaSex) {
                        ForEach(FormulaSex.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                } header: { Text("基本信息") } footer: { Text("公式的性别参数用于静息消耗估算；不代表性别认同。若不适用，应由专业人员评估。") }
                Section("目标与饮食") {
                    Picker("当前目标", selection: $draft.goal) {
                        ForEach(Goal.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Picker("饮食偏好", selection: $draft.diet) {
                        ForEach(Diet.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                }
                Section {
                    ForEach(Allergen.allCases, id: \.self) { allergen in
                        Toggle(allergen.title, isOn: Binding(get: { draft.allergens.contains(allergen) }, set: { selected in
                            if selected { draft.allergens.insert(allergen) } else { draft.allergens.remove(allergen) }
                        }))
                    }
                } header: { Text("需要排除的过敏原") } footer: {
                    Text("开启代表排除。此列表不涵盖全部过敏原；其他过敏食材请在下方排除。燕麦保守地归入小麦 / 麸质组。产品包装与交叉接触仍需自行核对。")
                }
                Section {
                    DisclosureGroup("不吃的食材 · 已选 \(draft.avoidedFoods.count) 种") {
                        ForEach(Catalog.foods.values.sorted { $0.id < $1.id }) { food in
                            Toggle(food.name, isOn: Binding(get: { draft.avoidedFoods.contains(food.id) }, set: { selected in
                                if selected { draft.avoidedFoods.insert(food.id) } else { draft.avoidedFoods.remove(food.id) }
                            }))
                        }
                    }
                }
                Section {
                    Toggle("需要专业饮食方案", isOn: $draft.needsProfessionalPlan)
                } header: { Text("适用情况") } footer: {
                    Text("孕期、哺乳期、进食障碍，或疾病、用药需要限制饮食时请开启；开启后暂停自动推荐。本版仅为 18–64 岁的一般健康成人提供参考。")
                }
                Section {
                    Button {
                        guard draft.heightCM.isFinite, draft.weightKG.isFinite,
                              (1...120).contains(draft.age), (80...250).contains(draft.heightCM), (20...300).contains(draft.weightKG) else {
                            error = "请填写有效的年龄、身高和体重。"
                            return
                        }
                        draft.name = String(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(20))
                        draft.completed = true
                        store.saveProfile(draft)
                        dismiss()
                    } label: {
                        Text(onboarding ? "保存并查看菜单" : "保存档案").frame(maxWidth: .infinity).padding(.vertical, 7)
                    }
                    .modifier(GlassPrimary())
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle(onboarding ? "认识你" : "个人档案")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !onboarding { ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
                }
            }
            .alert("请核对资料", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("知道了") { error = nil }
            } message: { Text(error ?? "") }
        }
    }

    private func numericRow(_ title: String, value: Binding<Double>, unit: String) -> some View {
        HStack {
            Text(title)
            TextField(title, value: value, format: .number).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
            Text(unit).foregroundStyle(.secondary)
        }
    }

    private func numericRow(_ title: String, value: Binding<Int>, unit: String) -> some View {
        HStack {
            Text(title)
            TextField(title, value: value, format: .number).keyboardType(.numberPad).multilineTextAlignment(.trailing)
            Text(unit).foregroundStyle(.secondary)
        }
    }
}
