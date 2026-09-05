import Foundation

enum Planner {
    static func budget(profile p: Profile, activity a: DailyActivity) throws -> EnergyBudget {
        guard p.heightCM.isFinite, p.weightKG.isFinite,
              (18...64).contains(p.age), (130...220).contains(p.heightCM), (40...180).contains(p.weightKG) else {
            throw PlannerError.invalidProfile
        }
        guard !p.needsProfessionalPlan, p.bmi >= 18.5, p.bmi < 40 else { throw PlannerError.professionalPlan }
        let resting = 10 * p.weightKG + 6.25 * p.heightCM - 5 * Double(p.age) + p.formulaSex.offset
        var notes: [String] = []
        let active: Double
        switch a.source {
        case .healthKit:
            guard let value = a.healthActiveKcal else { throw PlannerError.missingHealthData }
            active = value
            notes.append("按所选日期已同步的活动热量估算；当天继续活动后可重新同步。步数与运动记录不重复累加。")
        case .manual:
            active = a.manualActiveKcal
            notes.append("使用你填写的全天活动热量，不包含静息热量；其他运动记录不重复累加。")
        case .workouts:
            guard a.workouts.allSatisfy({ $0.minutes.isFinite && (1...180).contains($0.minutes) }),
                  a.workouts.reduce(0, { $0 + $1.minutes }) <= 360 else { throw PlannerError.invalidActivity }
            active = resting * 0.12 + a.workouts.reduce(0) { $0 + $1.netKcal(weightKG: p.weightKG) }
            notes.append("日常活动暂按静息消耗的 12% 估算，再加运动净消耗。体力劳动者宜使用全天活动热量。")
        }
        guard active.isFinite, active >= 0 else { throw PlannerError.invalidActivity }
        guard active <= 1800 else { throw PlannerError.activityOutOfRange }
        // Explicit product assumptions; do not multiply a high activity factor and add workouts again.
        let maintenance = (resting + active) / 0.90
        let proposed = maintenance * (1 + p.goal.adjustment)
        let lowerBound = max(1500, resting)
        let target = max(lowerBound, proposed).rounded()
        guard target <= 3800 else { throw PlannerError.activityOutOfRange }
        if proposed < lowerBound { notes.append("已采用本版保守热量下限；这不代表个人医学上的最低摄入量。") }
        notes.append("公式与食材营养均为估算，食物热效应暂按 10% 计。菜单供一般健康成人日常参考。")
        return EnergyBudget(resting: resting, active: active, maintenance: maintenance, target: target, notes: notes)
    }

    static func eligible(_ recipe: Recipe, profile: Profile, foods: [String: Food] = Catalog.foods) -> Bool {
        recipe.ingredients.allSatisfy { ingredient in
            guard let food = foods[ingredient.foodID], !profile.avoidedFoods.contains(food.id),
                  food.allergens.isDisjoint(with: profile.allergens) else { return false }
            switch profile.diet {
            case .balanced: return true
            case .vegetarian: return food.vegetarian
            case .vegan: return food.vegan
            }
        }
    }

    static func nutrition(_ ingredients: [Ingredient], foods: [String: Food] = Catalog.foods) -> Nutrition {
        ingredients.reduce(Nutrition()) { sum, item in
            sum + (foods[item.foodID]?.per100g.scaled(item.grams / 100) ?? Nutrition())
        }
    }

    static func stableHash(_ string: String) -> UInt64 {
        string.utf8.reduce(UInt64(14695981039346656037)) { ($0 ^ UInt64($1)) &* 1099511628211 }
    }

    static func make(profile: Profile, activity: DailyActivity, day: String,
                     variations: [String: Int] = [:], recipes: [Recipe] = Catalog.recipes) throws -> MenuPlan {
        let budget = try budget(profile: profile, activity: activity)
        var meals: [Meal] = []
        var missing: [MealSlot] = []
        var notes: [String] = []
        for slot in MealSlot.allCases {
            let allowed = recipes.filter { $0.slots.contains(slot) && eligible($0, profile: profile) }.sorted { $0.id < $1.id }
            let proteinForward = allowed.filter {
                let n = nutrition($0.ingredients)
                return n.kcal > 0 && n.protein * 4 / n.kcal >= 0.18
            }
            let candidates = profile.goal == .muscle && !proteinForward.isEmpty ? proteinForward : allowed
            guard !candidates.isEmpty else { missing.append(slot); continue }
            let rotation = UInt64(max(0, variations[slot.rawValue, default: 0]))
            let index = Int((stableHash(day + slot.rawValue) % UInt64(candidates.count) + rotation % UInt64(candidates.count)) % UInt64(candidates.count))
            let recipe = candidates[index]
            let base = nutrition(recipe.ingredients).kcal
            guard base > 0 else { missing.append(slot); continue }
            let desiredScale = budget.target * slot.fraction / base
            let scale = min(1.8, max(0.65, desiredScale))
            let ingredients = recipe.ingredients.map { ingredient -> Ingredient in
                let unit = Catalog.foods[ingredient.foodID]?.roundingGrams ?? 5
                let grams = max(unit, (ingredient.grams * scale / unit).rounded() * unit)
                return Ingredient(foodID: ingredient.foodID, grams: grams)
            }
            meals.append(Meal(slot: slot, recipe: recipe, ingredients: ingredients,
                              nutrition: nutrition(ingredients), alternatives: candidates.count - 1))
        }
        if !missing.isEmpty { notes.append("有餐次暂时没有符合限制的菜谱。已保留限制，请添加适合的菜谱后再生成完整菜单。") }
        let total = meals.reduce(0) { $0 + $1.nutrition.kcal }
        if missing.isEmpty && abs(total - budget.target) / budget.target > 0.10 {
            notes.append("当前餐食总量与估算目标相差超过 10%，请尝试换餐；本版不会通过不合理放大份量强行配平。")
        }
        if !profile.allergens.isEmpty { notes.append("已排除所选过敏原的已知食材；仍需核对包装、调味料与交叉接触，不能保证无过敏风险。") }
        return MenuPlan(budget: budget, meals: meals, missingSlots: missing, notes: notes)
    }
}
