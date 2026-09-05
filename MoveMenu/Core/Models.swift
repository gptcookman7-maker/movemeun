import Foundation

enum FormulaSex: String, CaseIterable, Codable, Sendable {
    case female, male
    var title: String { self == .female ? "女性公式" : "男性公式" }
    var offset: Double { self == .female ? -161 : 5 }
}

enum Goal: String, CaseIterable, Codable, Sendable {
    case maintain, gentleLoss, muscle
    var title: String {
        switch self { case .maintain: "维持状态"; case .gentleLoss: "温和减脂"; case .muscle: "支持增肌" }
    }
    var adjustment: Double {
        switch self { case .maintain: 0; case .gentleLoss: -0.10; case .muscle: 0.05 }
    }
}

enum Diet: String, CaseIterable, Codable, Sendable {
    case balanced, vegetarian, vegan
    var title: String {
        switch self { case .balanced: "均衡饮食"; case .vegetarian: "蛋奶素"; case .vegan: "纯植物" }
    }
}

enum Allergen: String, CaseIterable, Codable, Hashable, Sendable {
    case milk, egg, soy, wheat, peanut, treeNut, fish, shellfish, sesame
    var title: String {
        switch self {
        case .milk: "乳制品"; case .egg: "鸡蛋"; case .soy: "大豆"; case .wheat: "小麦 / 麸质"
        case .peanut: "花生"; case .treeNut: "树坚果"; case .fish: "鱼类"; case .shellfish: "甲壳贝类"; case .sesame: "芝麻"
        }
    }
}

struct Profile: Codable, Equatable, Sendable {
    var name = ""
    var age = 30
    var formulaSex: FormulaSex = .female
    var heightCM = 165.0
    var weightKG = 60.0
    var goal: Goal = .maintain
    var diet: Diet = .balanced
    var allergens: Set<Allergen> = []
    var avoidedFoods: Set<String> = []
    var needsProfessionalPlan = false
    var completed = false
    var bmi: Double { weightKG / pow(heightCM / 100, 2) }
}

enum WorkoutKind: String, CaseIterable, Codable, Sendable {
    case walking, jogging, strength, yoga
    var title: String {
        switch self {
        case .walking: "快走 · 约 5.6–6.3 km/h"
        case .jogging: "慢跑 · 自选配速"
        case .strength: "力量 · 多动作 8–15 次"
        case .yoga: "哈他瑜伽"
        }
    }
    var symbol: String {
        switch self { case .walking: "figure.walk"; case .jogging: "figure.run"; case .strength: "dumbbell.fill"; case .yoga: "figure.yoga" }
    }
    // 2024 Adult Compendium codes: 17200, 12020, 02054, 02150.
    var met: Double {
        switch self { case .walking: 4.8; case .jogging: 7.5; case .strength: 3.5; case .yoga: 2.3 }
    }
}

struct Workout: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var kind: WorkoutKind
    var minutes: Double
    func netKcal(weightKG: Double) -> Double {
        (kind.met - 1) * weightKG * minutes / 60
    }
}

enum ActivitySource: String, CaseIterable, Codable, Sendable {
    case workouts, manual, healthKit
    var title: String {
        switch self { case .workouts: "按运动估算"; case .manual: "手动填活动热量"; case .healthKit: "Apple 健康" }
    }
}

struct DailyActivity: Codable, Equatable, Sendable {
    var source: ActivitySource = .workouts
    var workouts: [Workout] = []
    var manualActiveKcal = 0.0
    var healthActiveKcal: Double?
    var healthSteps: Double?
    var healthExerciseMinutes: Double?
    var syncedAt: Date?
}

enum MealSlot: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var title: String {
        switch self { case .breakfast: "早餐"; case .lunch: "午餐"; case .dinner: "晚餐"; case .snack: "加餐" }
    }
    var symbol: String {
        switch self { case .breakfast: "sunrise.fill"; case .lunch: "sun.max.fill"; case .dinner: "moon.stars.fill"; case .snack: "leaf.fill" }
    }
    var fraction: Double {
        switch self { case .breakfast: 0.25; case .lunch: 0.35; case .dinner: 0.30; case .snack: 0.10 }
    }
}

struct Nutrition: Codable, Equatable, Sendable {
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    // Approximate energy using 4/4/9; recipe values are estimates, not laboratory results.
    var kcal: Double { protein * 4 + carbs * 4 + fat * 9 }
    static func + (lhs: Self, rhs: Self) -> Self {
        Self(protein: lhs.protein + rhs.protein, carbs: lhs.carbs + rhs.carbs, fat: lhs.fat + rhs.fat)
    }
    func scaled(_ factor: Double) -> Self {
        Self(protein: protein * factor, carbs: carbs * factor, fat: fat * factor)
    }
}

struct Food: Codable, Identifiable, Sendable {
    var id: String
    var name: String
    var per100g: Nutrition
    var allergens: Set<Allergen>
    var vegan: Bool
    var vegetarian: Bool
    var roundingGrams: Double = 5
}

struct Ingredient: Codable, Sendable {
    var foodID: String
    var grams: Double
}

struct Recipe: Codable, Identifiable, Sendable {
    var id: String
    var name: String
    var slots: [MealSlot]
    var minutes: Int
    var ingredients: [Ingredient]
    var steps: [String]
}

struct Meal: Identifiable, Sendable {
    var slot: MealSlot
    var recipe: Recipe
    var ingredients: [Ingredient]
    var nutrition: Nutrition
    var alternatives: Int
    var id: String { slot.rawValue }
}

struct EnergyBudget: Sendable {
    var resting: Double
    var active: Double
    var maintenance: Double
    var target: Double
    var notes: [String]
}

struct MenuPlan: Sendable {
    var budget: EnergyBudget
    var meals: [Meal]
    var missingSlots: [MealSlot]
    var notes: [String]
    var total: Nutrition { meals.reduce(Nutrition()) { $0 + $1.nutrition } }
}

enum PlannerError: LocalizedError, Equatable {
    case invalidProfile, professionalPlan, invalidActivity, missingHealthData, activityOutOfRange
    var errorDescription: String? {
        switch self {
        case .invalidProfile: "请核对年龄、身高和体重。本版支持 18–64 岁、身高 130–220 cm、体重 40–180 kg 的成人。"
        case .professionalPlan: "你的情况需要单独评估。本版暂不生成热量菜单，请让医生或营养师帮助制定方案。"
        case .invalidActivity: "请核对运动数据：活动热量不能为负数，单次运动应在 1–180 分钟之间。"
        case .missingHealthData: "没有可用的活动热量。可能尚无记录或读取未获授权，可以改用手动记录。"
        case .activityOutOfRange: "当前消耗超出本版的常规活动范围，请核对记录或咨询运动营养师。"
        }
    }
}

enum DayKey {
    static func make(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 2000, c.month ?? 1, c.day ?? 1)
    }
}
