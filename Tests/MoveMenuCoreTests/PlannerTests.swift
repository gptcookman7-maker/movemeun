import XCTest
@testable import MoveMenuCore

final class PlannerTests: XCTestCase {
    private var profile: Profile {
        Profile(age: 30, formulaSex: .male, heightCM: 175, weightKG: 70, completed: true)
    }

    func testRestingEquationUsesProfile() throws {
        let b = try Planner.budget(profile: profile, activity: DailyActivity())
        XCTAssertEqual(b.resting, 1648.75, accuracy: 0.001)
        var female = profile
        female.formulaSex = .female
        XCTAssertEqual(try Planner.budget(profile: female, activity: DailyActivity()).resting, b.resting - 166, accuracy: 0.001)
    }

    func testMoreExerciseIncreasesTarget() throws {
        let rest = try Planner.budget(profile: profile, activity: DailyActivity())
        var active = DailyActivity()
        active.workouts = [Workout(kind: .jogging, minutes: 45)]
        let exercise = try Planner.budget(profile: profile, activity: active)
        XCTAssertGreaterThan(exercise.target, rest.target)
        XCTAssertEqual(exercise.active - rest.active, 341.25, accuracy: 0.001)
    }

    func testHealthModeDoesNotDoubleCountWorkoutsOrSteps() throws {
        var activity = DailyActivity(source: .healthKit, healthActiveKcal: 500)
        let baseline = try Planner.budget(profile: profile, activity: activity)
        activity.workouts = [Workout(kind: .jogging, minutes: 60)]
        activity.healthSteps = 15000
        activity.manualActiveKcal = 1000
        XCTAssertEqual(try Planner.budget(profile: profile, activity: activity).target, baseline.target)
        XCTAssertEqual(baseline.active, 500)
    }

    func testManualModeDoesNotDoubleCountHealthData() throws {
        let activity = DailyActivity(source: .manual, workouts: [Workout(kind: .walking, minutes: 30)],
                                     manualActiveKcal: 300, healthActiveKcal: 900)
        XCTAssertEqual(try Planner.budget(profile: profile, activity: activity).active, 300)
    }

    func testMissingHealthIsDifferentFromZero() throws {
        XCTAssertThrowsError(try Planner.budget(profile: profile, activity: DailyActivity(source: .healthKit))) {
            XCTAssertEqual($0 as? PlannerError, .missingHealthData)
        }
        XCTAssertEqual(try Planner.budget(profile: profile, activity: DailyActivity(source: .healthKit, healthActiveKcal: 0)).active, 0)
    }

    func testNonfiniteAndNegativeInputsAreRejected() {
        for number in [Double.nan, Double.infinity, -1] {
            XCTAssertThrowsError(try Planner.budget(profile: profile, activity: DailyActivity(source: .manual, manualActiveKcal: number)))
        }
        var p = profile
        p.weightKG = .nan
        XCTAssertThrowsError(try Planner.budget(profile: p, activity: DailyActivity()))
    }

    func testSpecialSituationsDoNotGeneratePlans() {
        var p = profile
        p.needsProfessionalPlan = true
        XCTAssertThrowsError(try Planner.make(profile: p, activity: DailyActivity(), day: "2026-09-06"))
        p.needsProfessionalPlan = false
        p.age = 17
        XCTAssertThrowsError(try Planner.make(profile: p, activity: DailyActivity(), day: "2026-09-06"))
        p.age = 30
        p.weightKG = 45
        XCTAssertThrowsError(try Planner.make(profile: p, activity: DailyActivity(), day: "2026-09-06"))
    }

    func testExtremeExerciseIsNotSilentlyClamped() {
        XCTAssertThrowsError(try Planner.budget(profile: profile, activity: DailyActivity(source: .manual, manualActiveKcal: 2200)))
        XCTAssertThrowsError(try Planner.budget(profile: profile,
            activity: DailyActivity(workouts: [Workout(kind: .jogging, minutes: 181)])))
    }

    func testEveryAllergenCombinationIsRespected() throws {
        let all = Allergen.allCases
        for mask in 0..<(1 << all.count) {
            var p = profile
            p.allergens = Set(all.enumerated().compactMap { (mask & (1 << $0.offset)) != 0 ? $0.element : nil })
            let plan = try Planner.make(profile: p, activity: DailyActivity(), day: "2026-09-06")
            for meal in plan.meals {
                for ingredient in meal.ingredients {
                    let food = try XCTUnwrap(Catalog.foods[ingredient.foodID])
                    XCTAssertTrue(food.allergens.isDisjoint(with: p.allergens), "\(food.id) mask \(mask)")
                }
            }
        }
    }

    func testVeganAndAvoidedFoodFilters() throws {
        var p = profile
        p.diet = .vegan
        p.avoidedFoods = ["tofu", "chickpea"]
        let plan = try Planner.make(profile: p, activity: DailyActivity(), day: "2026-09-06")
        XCTAssertTrue(plan.missingSlots.isEmpty)
        for meal in plan.meals {
            for ingredient in meal.ingredients {
                XCTAssertTrue(try XCTUnwrap(Catalog.foods[ingredient.foodID]).vegan)
                XCTAssertFalse(p.avoidedFoods.contains(ingredient.foodID))
            }
        }
    }

    func testNoMatchesNeverRelaxRestrictions() throws {
        var p = profile
        p.avoidedFoods = Set(Catalog.foods.keys)
        let plan = try Planner.make(profile: p, activity: DailyActivity(), day: "2026-09-06")
        XCTAssertEqual(plan.missingSlots.count, 4)
        XCTAssertTrue(plan.meals.isEmpty)
    }

    func testSwappingChangesOnlySelectedMeal() throws {
        let first = try Planner.make(profile: profile, activity: DailyActivity(), day: "2026-09-06")
        let second = try Planner.make(profile: profile, activity: DailyActivity(), day: "2026-09-06", variations: ["lunch": 1])
        XCTAssertNotEqual(first.meals.first { $0.slot == .lunch }?.recipe.id, second.meals.first { $0.slot == .lunch }?.recipe.id)
        for slot in [MealSlot.breakfast, .dinner, .snack] {
            XCTAssertEqual(first.meals.first { $0.slot == slot }?.recipe.id, second.meals.first { $0.slot == slot }?.recipe.id)
        }
    }

    func testMenusAreDeterministicAndRotateByDay() throws {
        let a = try Planner.make(profile: profile, activity: DailyActivity(), day: "2026-09-06")
        let b = try Planner.make(profile: profile, activity: DailyActivity(), day: "2026-09-06")
        let c = try Planner.make(profile: profile, activity: DailyActivity(), day: "2026-09-07")
        XCTAssertEqual(a.meals.map(\.recipe.id), b.meals.map(\.recipe.id))
        XCTAssertNotEqual(a.meals.map(\.recipe.id), c.meals.map(\.recipe.id))
    }

    func testNutritionMatchesRoundedIngredientWeights() throws {
        let plan = try Planner.make(profile: profile, activity: DailyActivity(), day: "2026-09-06")
        for meal in plan.meals {
            XCTAssertEqual(meal.nutrition, Planner.nutrition(meal.ingredients))
            XCTAssertTrue(meal.ingredients.allSatisfy { $0.grams > 0 && $0.grams.isFinite })
        }
        XCTAssertEqual(plan.total.kcal, plan.meals.reduce(0) { $0 + $1.nutrition.kcal }, accuracy: 0.001)
    }

    func testAllRecipesHaveValidIngredientsAndSteps() {
        XCTAssertEqual(Set(Catalog.recipes.map(\.id)).count, Catalog.recipes.count)
        for recipe in Catalog.recipes {
            XCTAssertFalse(recipe.steps.isEmpty)
            XCTAssertFalse(recipe.slots.isEmpty)
            XCTAssertGreaterThan(Planner.nutrition(recipe.ingredients).kcal, 0)
            for ingredient in recipe.ingredients { XCTAssertNotNil(Catalog.foods[ingredient.foodID]) }
        }
    }

    func testDateKeysFollowLocalCalendarAcrossMidnight() throws {
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-09-05T18:00:00Z"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Shanghai"))
        XCTAssertEqual(DayKey.make(date, calendar: calendar), "2026-09-06")
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        XCTAssertEqual(DayKey.make(date, calendar: calendar), "2026-09-05")
    }
}
