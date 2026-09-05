import SwiftUI

struct TodayView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedMeal: Meal?
    @State private var showProfile = false
    @State private var showDate = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(store.selectedDate.formatted(.dateTime.month(.wide).day().weekday(.wide)))
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text(store.profile.name.isEmpty ? "为今天，好好吃饭。" : "\(store.profile.name)，好好吃饭。")
                                .font(.title2.weight(.semibold))
                        }
                        Spacer(minLength: 12)
                        Button { showDate = true } label: {
                            Image(systemName: "calendar").frame(width: 28, height: 28)
                        }
                        .modifier(GlassSecondary())
                        .accessibilityLabel("选择菜单日期")
                    }
                    if store.profile.completed {
                        switch store.plan {
                        case .success(let plan):
                            budgetCard(plan)
                            HStack {
                                Text("今日四餐").font(.title2.bold())
                                Spacer()
                                Text(store.profile.diet.title).font(.subheadline).foregroundStyle(.secondary)
                            }
                            ForEach(plan.meals) { meal in mealRow(meal) }
                            ForEach(plan.missingSlots) { slot in
                                Card {
                                    Label("\(slot.title) · 暂无符合限制的菜谱", systemImage: "leaf")
                                        .font(.headline)
                                    Text("保留你的饮食限制，先不要套用不合适的食谱。")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            ForEach(plan.notes, id: \.self) { Note(text: $0) }
                            DisclosureGroup("估算依据") {
                                VStack(alignment: .leading, spacing: 14) {
                                    LabeledContent("静息消耗", value: "约 \(plan.budget.resting.whole) kcal")
                                    LabeledContent("活动消耗", value: "约 \(plan.budget.active.whole) kcal")
                                    LabeledContent("目标", value: store.profile.goal.title)
                                    ForEach(plan.budget.notes, id: \.self) { Text($0).font(.subheadline).foregroundStyle(.secondary) }
                                }.padding(.top, 14)
                            }
                            .font(.subheadline)
                            .padding(20)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 22))
                        case .failure(let error):
                            ContentUnavailableView {
                                Label("先完善今天的信息", systemImage: "slider.horizontal.3")
                            } description: { Text(error.localizedDescription) } actions: {
                                Button("调整个人档案") { showProfile = true }.modifier(GlassPrimary())
                            }
                        }
                    }
                    Text("营养数值为估算；菜单总量不表示你已经吃下的热量。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(20)
                .frame(maxWidth: 680)
                .frame(maxWidth: .infinity)
            }
            .background(ScreenBackground())
            .navigationTitle("动膳")
            .sheet(item: $selectedMeal) { MealDetailView(meal: $0) }
            .sheet(isPresented: $showProfile) { ProfileEditor(initial: store.profile) }
            .sheet(isPresented: $showDate) { DateSelectionView() }
        }
    }

    private func budgetCard(_ plan: MenuPlan) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 22) {
                Label("随运动调整的每日菜单", systemImage: "sparkles").font(.subheadline).foregroundStyle(.teal)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 20) { energyText(plan); Spacer(minLength: 0); energyRing(plan) }
                    VStack(alignment: .leading, spacing: 16) { energyText(plan); energyRing(plan) }
                }
                Divider()
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { macros(plan.total) }
                    VStack(alignment: .leading, spacing: 16) { macros(plan.total) }
                }
            }
        }
    }

    private func energyText(_ plan: MenuPlan) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("估算摄入目标").font(.subheadline).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(plan.budget.target.whole).font(.system(.largeTitle, design: .rounded, weight: .semibold))
                    .monospacedDigit().contentTransition(.numericText())
                Text("kcal").font(.subheadline).foregroundStyle(.secondary)
            }
            Text("菜单合计 \(plan.total.kcal.whole) kcal").font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private func energyRing(_ plan: MenuPlan) -> some View {
        let ratio = min(1, max(0, plan.total.kcal / plan.budget.target))
        return ZStack {
            Circle().stroke(.teal.opacity(0.10), lineWidth: 9)
            Circle().trim(from: 0, to: ratio)
                .stroke(AngularGradient(colors: [.teal.opacity(0.4), .teal], center: .center),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: "fork.knife").font(.title2).foregroundStyle(.teal)
        }
        .frame(width: 84, height: 84)
        .accessibilityLabel("菜单达到估算目标的 \((100 * plan.total.kcal / plan.budget.target).whole)%")
    }

    @ViewBuilder private func macros(_ nutrition: Nutrition) -> some View {
        Metric(title: "蛋白质", value: "\(nutrition.protein.whole) g", color: .teal)
        Metric(title: "碳水", value: "\(nutrition.carbs.whole) g", color: .orange)
        Metric(title: "脂肪", value: "\(nutrition.fat.whole) g", color: .indigo)
    }

    private func mealRow(_ meal: Meal) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label(meal.slot.title, systemImage: meal.slot.symbol).font(.subheadline).foregroundStyle(.teal)
                    Spacer()
                    Text("\(meal.recipe.minutes) 分钟").font(.subheadline).foregroundStyle(.secondary)
                }
                Button { selectedMeal = meal } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(meal.recipe.name).font(.title3.bold()).foregroundStyle(.primary)
                        Text(meal.ingredients.compactMap { Catalog.foods[$0.foodID]?.name.components(separatedBy: "（").first }
                            .joined(separator: " · "))
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                    }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityHint("查看食材份量和做法")
                HStack {
                    Text("约 \(meal.nutrition.kcal.whole) kcal").font(.headline).monospacedDigit()
                    Spacer()
                    Button {
                        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) { store.swap(meal.slot) }
                    } label: { Label("换一道", systemImage: "arrow.triangle.2.circlepath").font(.subheadline) }
                        .modifier(GlassSecondary())
                        .disabled(meal.alternatives == 0)
                        .accessibilityLabel("更换\(meal.slot.title)")
                }
                if meal.alternatives == 0 {
                    Text("当前限制下只有这一道餐食。").font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct DateSelectionView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        @Bindable var binding = store
        NavigationStack {
            DatePicker("菜单日期", selection: $binding.selectedDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical).padding()
                .navigationTitle("选择日期")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }.presentationDetents([.medium, .large])
    }
}

struct MealDetailView: View {
    var meal: Meal
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("估算热量", value: "\(meal.nutrition.kcal.whole) kcal")
                    LabeledContent("蛋白质", value: "\(meal.nutrition.protein.whole) g")
                    LabeledContent("碳水化合物", value: "\(meal.nutrition.carbs.whole) g")
                    LabeledContent("脂肪", value: "\(meal.nutrition.fat.whole) g")
                } header: { Text(meal.slot.title + " · 约 \(meal.recipe.minutes) 分钟") }
                Section("这一餐的份量") {
                    ForEach(meal.ingredients, id: \.foodID) { ingredient in
                        LabeledContent(Catalog.foods[ingredient.foodID]?.name ?? ingredient.foodID,
                                       value: "\(ingredient.grams.whole) g")
                    }
                }
                Section("简单做法") {
                    ForEach(Array(meal.recipe.steps.enumerated()), id: \.offset) { item in
                        HStack(alignment: .top, spacing: 14) {
                            Text("\(item.offset + 1)").font(.headline).foregroundStyle(.teal)
                            Text(item.element)
                        }.padding(.vertical, 6)
                    }
                }
                Section {
                    Text("份量按可食部分称量，熟重与干重见食材名称。油已计入；额外调味料需另计。常见食材营养会随品种和做法变化。")
                    Text("有过敏史时，请核对每一种食材的包装与制作环境。不要自行添加不明成分的酱料。")
                }.font(.footnote).foregroundStyle(.secondary)
            }
            .navigationTitle(meal.recipe.name).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完成") { dismiss() } } }
        }
    }
}
