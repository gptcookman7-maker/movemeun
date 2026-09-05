import Foundation

enum Catalog {
    // Generic, illustrative per-100g macros. Review against a licensed food database before release.
    // All portions use edible cooked weight unless the name explicitly says otherwise.
    static let foods: [String: Food] = {
        func f(_ id: String, _ name: String, _ p: Double, _ c: Double, _ fat: Double,
               _ allergens: Set<Allergen> = [], vegan: Bool = true, vegetarian: Bool = true,
               unit: Double = 5) -> Food {
            Food(id: id, name: name, per100g: Nutrition(protein: p, carbs: c, fat: fat),
                 allergens: allergens, vegan: vegan, vegetarian: vegetarian, roundingGrams: unit)
        }
        let entries = [
            f("oats", "燕麦片（干重）", 13, 62, 7, [.wheat]),
            f("rice", "糙米饭（熟重）", 2.6, 23, 0.9),
            f("whiteRice", "米饭（熟重）", 2.7, 28, 0.3),
            f("quinoa", "藜麦（熟重）", 4.4, 21.3, 1.9),
            f("potato", "土豆（熟重）", 2, 20, 0.1),
            f("sweetPotato", "红薯（熟重）", 1.6, 20.7, 0.1),
            f("corn", "玉米粒（熟重）", 3.4, 21, 1.5),
            f("bread", "全麦面包", 10, 43, 4, [.wheat]),
            f("chicken", "鸡胸肉（熟重）", 31, 0, 3.6, vegan: false, vegetarian: false),
            f("beef", "瘦牛肉（熟重）", 26, 0, 8, vegan: false, vegetarian: false),
            f("salmon", "三文鱼（熟重）", 22, 0, 12, [.fish], vegan: false, vegetarian: false),
            f("tofu", "北豆腐", 12, 3, 7, [.soy]),
            f("chickpea", "鹰嘴豆（熟重）", 8.9, 27.4, 2.6),
            f("lentil", "扁豆（熟重）", 9, 20, 0.4),
            f("egg", "鸡蛋（去壳熟重）", 12.6, 1.1, 10.6, [.egg], vegan: false),
            f("yogurt", "原味希腊酸奶", 9, 4, 2, [.milk], vegan: false),
            f("milk", "低脂牛奶", 3.4, 5, 1.5, [.milk], vegan: false),
            f("soyMilk", "无糖豆浆", 3, 2, 1.6, [.soy]),
            f("broccoli", "西兰花（熟重）", 2.8, 7, 0.4),
            f("spinach", "菠菜（熟重）", 3, 4, 0.4),
            f("tomato", "番茄", 0.9, 3.9, 0.2),
            f("carrot", "胡萝卜（熟重）", 0.8, 8, 0.2),
            f("mushroom", "鲜蘑菇（熟重）", 3, 5, 0.4),
            f("avocado", "牛油果（去皮去核）", 2, 8.5, 14.7),
            f("banana", "香蕉（去皮）", 1.1, 23, 0.3),
            f("apple", "苹果（去核）", 0.3, 14, 0.2),
            f("berries", "蓝莓", 0.7, 14.5, 0.3),
            f("almond", "杏仁", 21, 22, 50, [.treeNut]),
            f("pumpkinSeed", "南瓜籽仁", 30, 11, 49),
            f("oliveOil", "橄榄油", 0, 0, 100, unit: 1)
        ]
        return Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
    }()

    static let recipes: [Recipe] = {
        func r(_ id: String, _ name: String, _ slots: [MealSlot], _ minutes: Int,
               _ items: [(String, Double)], _ steps: [String]) -> Recipe {
            Recipe(id: id, name: name, slots: slots, minutes: minutes,
                   ingredients: items.map { Ingredient(foodID: $0.0, grams: $0.1) }, steps: steps)
        }
        let breakfast: [MealSlot] = [.breakfast]
        let main: [MealSlot] = [.lunch, .dinner]
        let snack: [MealSlot] = [.snack]
        return [
            r("b01", "蓝莓酸奶燕麦碗", breakfast, 10,
              [("oats", 50), ("yogurt", 180), ("berries", 80), ("almond", 10)],
              ["燕麦加水煮熟，放至温热。", "加入原味酸奶、洗净的蓝莓与杏仁。"]),
            r("b02", "牛油果鸡蛋吐司", breakfast, 12,
              [("bread", 90), ("egg", 100), ("avocado", 50), ("tomato", 100)],
              ["鸡蛋充分煮熟，面包烤至微脆。", "铺上牛油果泥、鸡蛋和番茄。"]),
            r("b03", "香蕉豆乳燕麦", breakfast, 10,
              [("oats", 65), ("soyMilk", 250), ("banana", 80), ("pumpkinSeed", 10)],
              ["燕麦与豆浆一起煮熟。", "加入香蕉片，撒上南瓜籽仁。"]),
            r("b04", "藜麦鹰嘴豆暖碗", breakfast, 15,
              [("quinoa", 160), ("chickpea", 100), ("tomato", 100), ("oliveOil", 8)],
              ["将熟藜麦和熟鹰嘴豆加热。", "加入番茄和橄榄油拌匀，可用柠檬汁调味。"]),
            r("b05", "红薯鸡蛋牛奶", breakfast, 15,
              [("sweetPotato", 200), ("egg", 100), ("milk", 250)],
              ["红薯蒸熟，鸡蛋充分煮熟。", "按清单称取可食部分，搭配牛奶。"]),
            r("b06", "玉米扁豆早餐碗", breakfast, 15,
              [("corn", 150), ("lentil", 150), ("avocado", 50), ("tomato", 100)],
              ["玉米、扁豆分别煮熟，按熟重称量。", "加入牛油果与番茄丁拌匀。"]),
            r("b07", "蘑菇豆腐糙米碗", breakfast, 15,
              [("rice", 170), ("tofu", 150), ("mushroom", 100), ("oliveOil", 6)],
              ["蘑菇切片，与豆腐用清单内的油炒熟。", "搭配加热的糙米饭。"]),
            r("m01", "柠檬鸡胸糙米饭", main, 25,
              [("chicken", 140), ("rice", 220), ("broccoli", 180), ("oliveOil", 12)],
              ["鸡胸肉煎或蒸至完全熟透，按熟重称量。", "西兰花蒸熟，搭配糙米饭。", "使用清单内的油，可加柠檬汁和少量盐。"]),
            r("m02", "三文鱼藜麦盘", main, 25,
              [("salmon", 140), ("quinoa", 200), ("spinach", 160), ("oliveOil", 7)],
              ["三文鱼烤至完全熟透。", "菠菜焯熟，搭配煮好的藜麦。", "淋上清单内的橄榄油。"]),
            r("m03", "番茄牛肉土豆饭", main, 30,
              [("beef", 140), ("potato", 180), ("whiteRice", 100), ("tomato", 180), ("oliveOil", 8)],
              ["牛肉、土豆和番茄炖至完全熟透。", "按熟重分装，搭配米饭。"]),
            r("m04", "香煎豆腐双谷碗", main, 20,
              [("tofu", 200), ("rice", 180), ("corn", 80), ("broccoli", 160), ("oliveOil", 8)],
              ["豆腐用清单内的油煎熟，西兰花和玉米煮熟。", "和糙米饭一起装盘，不额外添加含过敏原的酱料。"]),
            r("m05", "鹰嘴豆藜麦蔬菜碗", main, 20,
              [("chickpea", 170), ("quinoa", 180), ("carrot", 100), ("spinach", 100), ("oliveOil", 10)],
              ["提前将鹰嘴豆和藜麦煮熟。", "蔬菜蒸熟，按份量拌入豆谷和油。"]),
            r("m06", "番茄扁豆糙米饭", main, 25,
              [("lentil", 220), ("rice", 200), ("tomato", 180), ("oliveOil", 12)],
              ["扁豆充分煮熟后与番茄炖煮。", "按熟重分装，搭配糙米饭。"]),
            r("m07", "鸡蛋豆腐蔬菜饭", main, 20,
              [("egg", 100), ("tofu", 120), ("whiteRice", 200), ("spinach", 150), ("oliveOil", 8)],
              ["鸡蛋、豆腐、菠菜用清单内的油炒至完全熟透。", "搭配米饭，调味从简。"]),
            r("m08", "鸡肉红薯蘑菇盘", main, 25,
              [("chicken", 140), ("sweetPotato", 280), ("mushroom", 160), ("oliveOil", 15)],
              ["鸡肉充分烤熟，红薯蒸熟。", "蘑菇用油炒熟，按清单装盘。"]),
            r("m09", "扁豆土豆暖沙拉", main, 25,
              [("lentil", 230), ("potato", 230), ("tomato", 100), ("pumpkinSeed", 15), ("oliveOil", 10)],
              ["扁豆、土豆分别充分煮熟。", "加入番茄、南瓜籽和橄榄油拌匀。"]),
            r("m10", "藜麦豆腐蘑菇盘", main, 20,
              [("quinoa", 200), ("tofu", 200), ("mushroom", 150), ("oliveOil", 10)],
              ["豆腐和蘑菇用油炒熟。", "按熟重装盘，搭配藜麦。"]),
            r("s01", "原味酸奶与蓝莓", snack, 3,
              [("yogurt", 180), ("berries", 100), ("almond", 8)],
              ["蓝莓洗净，加入原味酸奶，撒上杏仁。"]),
            r("s02", "苹果与南瓜籽", snack, 3,
              [("apple", 160), ("pumpkinSeed", 22)], ["苹果洗净去核，搭配称量后的南瓜籽仁。"]),
            r("s03", "香蕉豆浆", snack, 3,
              [("banana", 120), ("soyMilk", 250)], ["香蕉去皮，搭配无糖豆浆。"]),
            r("s04", "烤鹰嘴豆小碗", snack, 12,
              [("chickpea", 120), ("oliveOil", 3)],
              ["将充分煮熟的鹰嘴豆沥干，与油拌匀。", "烤至表面微干，放凉后食用。"]),
            r("s05", "红薯与南瓜籽", snack, 15,
              [("sweetPotato", 140), ("pumpkinSeed", 14)], ["红薯蒸熟，搭配南瓜籽仁。"]),
            r("s06", "牛奶香蕉杯", snack, 3,
              [("milk", 250), ("banana", 100)], ["香蕉去皮切片，搭配牛奶食用。"])
        ]
    }()
}
