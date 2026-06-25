import Foundation

enum DeceasedGender: String, Codable {
    case male = "MALE"
    case female = "FEMALE"
}

enum FaraidhMadhhab: String, Codable, CaseIterable {
    case hanafi = "HANAFI"
    case maliki = "MALIKI"
    case shafii = "SHAFII"
    case hanbali = "HANBALI"
    
    func raddIncludesSpouses() -> Bool {
        return self == .hanafi
    }
}

struct FaraidhPropertyItem: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var sizeSqm: String = ""
    var value: String = ""
}

struct EstateAssetInput: Codable, Hashable {
    var cashSavings: String = ""
    var goldJewelry: String = ""
    var goldWeightGrams: String = ""
    var goldPricePerGram: String = ""
    var inputGoldByGrams: Bool = false
    var propertyValue: String = ""
    var properties: [FaraidhPropertyItem] = []
    var inputPropertyDetailed: Bool = false
    var businessAssets: String = ""
    var otherAssets: String = ""
    var hasResidentialProperty: Bool = false
    var propertyNotes: String = ""
    var debts: String = ""
    var funeralCosts: String = ""
    var unpaidZakat: String = ""
    var bequestWasiat: String = ""
}

struct EstateComputation: Codable, Hashable {
    var grossAssets: Decimal
    var cashComponent: Decimal
    var goldComponent: Decimal
    var propertyComponent: Decimal
    var businessComponent: Decimal
    var otherComponent: Decimal
    var funeralCosts: Decimal
    var debts: Decimal
    var unpaidZakat: Decimal
    var afterFuneral: Decimal
    var afterDebts: Decimal
    var afterZakat: Decimal
    var maxWasiat: Decimal
    var wasiatApplied: Decimal
    var netEstate: Decimal
    var hasResidentialProperty: Bool
    var propertyNotes: String
}

struct DeceasedProfile: Codable, Hashable {
    var gender: DeceasedGender
    var netEstate: Decimal
    var name: String = ""
    var estate: EstateComputation? = nil
    var madhhab: FaraidhMadhhab = .shafii
    var bornOutOfWedlock: Bool = false
}

struct DisqualifiedHeir: Codable, Hashable {
    var type: HeirType
    var count: Int
    var reason: BlockingReasonKey
}

struct HeirInput: Codable, Hashable {
    var husbandCount: Int = 0
    var wifeCount: Int = 0
    var fatherCount: Int = 0
    var grandfatherCount: Int = 0
    var motherCount: Int = 0
    var sonCount: Int = 0
    var daughterCount: Int = 0
    var grandsonCount: Int = 0
    var granddaughterCount: Int = 0
    var fullBrotherCount: Int = 0
    var fullSisterCount: Int = 0
    var paternalBrotherCount: Int = 0
    var paternalSisterCount: Int = 0
    var maternalBrotherCount: Int = 0
    var maternalSisterCount: Int = 0
    var disqualifiedHeirs: [DisqualifiedHeir] = []
    
    func hasAnyHeir() -> Bool {
        return husbandCount > 0 || wifeCount > 0 || fatherCount > 0 || grandfatherCount > 0 ||
               motherCount > 0 || sonCount > 0 || daughterCount > 0 || grandsonCount > 0 ||
               granddaughterCount > 0 || fullBrotherCount > 0 || fullSisterCount > 0 ||
               paternalBrotherCount > 0 || paternalSisterCount > 0 ||
               maternalBrotherCount > 0 || maternalSisterCount > 0 || !disqualifiedHeirs.isEmpty
    }
}

enum HeirType: String, Codable, CaseIterable {
    case husband = "HUSBAND"
    case wife = "WIFE"
    case father = "FATHER"
    case grandfather = "GRANDFATHER"
    case mother = "MOTHER"
    case son = "SON"
    case daughter = "DAUGHTER"
    case grandson = "GRANDSON"
    case granddaughter = "GRANDDAUGHTER"
    case fullBrother = "FULL_BROTHER"
    case fullSister = "FULL_SISTER"
    case paternalBrother = "PATERNAL_BROTHER"
    case paternalSister = "PATERNAL_SISTER"
    case maternalSibling = "MATERNAL_SIBLING"
    case stepChild = "STEP_CHILD"
    case unbornFetus = "UNBORN_FETUS"
}

enum BlockingReasonKey: String, Codable {
    case bySon = "BY_SON"
    case byChildren = "BY_CHILDREN"
    case byFather = "BY_FATHER"
    case byGrandfather = "BY_GRANDFATHER"
    case byGrandchildrenSubstitute = "BY_GRANDCHILDREN_SUBSTITUTE"
    case genderMismatch = "GENDER_MISMATCH"
    case noShareRemainder = "NO_SHARE_REMAINDER"
    case outOfWedlock = "OUT_OF_WEDLOCK"
    case homicide = "HOMICIDE"
    case differenceOfReligion = "DIFFERENCE_OF_RELIGION"
    case simultaneousDeath = "SIMULTANEOUS_DEATH"
}

enum FaraidhAdjustment: String, Codable {
    case none = "NONE"
    case awl = "AWL"
    case radd = "RADD"
}

struct HeirShare: Codable, Hashable {
    var type: HeirType
    var headCount: Int
    var fraction: FaraidhFraction
    var percentage: Decimal
    var cashAmount: Decimal
    var isAsabah: Bool
    var proofKeys: [String]
    var heirId: String { type.rawValue.lowercased() }
}

struct BlockedHeir: Codable, Hashable {
    var type: HeirType
    var headCount: Int
    var reason: BlockingReasonKey
}

struct SilsilahNode: Codable, Hashable, Identifiable {
    var id: String
    var parentNodeId: String?
    var generationLevel: Int
    var type: HeirType
    var labelKey: String
    var headCount: Int
    var inherits: Bool
    var blocked: Bool
    var blockReason: BlockingReasonKey?
    var displayName: String = ""
    var shareFraction: String? = nil
    var sharePercentage: String? = nil
    var shareAmount: Decimal? = nil
}

enum GraphNodeStatus: String, Codable {
    case active = "ACTIVE"
    case mahjubNuqsan = "MAHJUB_NUQSAN"
    case mahjubHirman = "MAHJUB_HIRMAN"
    case excludedByLaw = "EXCLUDED_BY_LAW"
    case frozenReserve = "FROZEN_RESERVE"
}

struct FaraidhGraphNode: Codable, Hashable, Identifiable {
    var id: String
    var displayName: String
    var generationLevel: Int
    var relationType: HeirType?
    var status: GraphNodeStatus
    var marriageLinkId: String? = nil
    var baseShareFraction: String? = nil
    var finalPercentage: Double = 0.0
    var cashValue: Decimal = .zero
    var disqualificationReasonId: String? = nil
    var visualColorHex: String
}

enum GraphEdgeType: String, Codable {
    case parentChild = "PARENT_CHILD"
    case marriage = "MARRIAGE"
    case motherOnlyMaternal = "MOTHER_ONLY_MATERNAL"
}

struct FaraidhGraphEdge: Codable, Hashable {
    var fromId: String
    var toId: String
    var type: GraphEdgeType
}

struct FaraidhFamilyGraph: Codable, Hashable {
    var rootDeceasedId: String
    var nodes: [String: FaraidhGraphNode]
    var edges: [FaraidhGraphEdge]
}

struct MunasakhatNode: Codable, Hashable {
    var deceasedId: String
    var deceasedName: String
    var netPersonalEstate: Decimal
    var input: HeirInput
    var subHeirs: [String: MunasakhatNode] = [:]
}

struct ContingencyInput: Codable, Hashable {
    var fetusCount: Int = 0
    var missingHeirType: HeirType? = nil
    var missingHeirCount: Int = 0
}

enum ClassicalCase: String, Codable {
    case alMinbariyah = "AL_MINBARIYAH"
    case alAkdariyah = "AL_AKDARIYAH"
    case alMarwaniyah = "AL_MARWANIYAH"
    case umariyatain = "UMARIYATAIN"
}

struct FaraidhResult: Codable, Hashable {
    var deceased: DeceasedProfile
    var input: HeirInput
    var activeShares: [HeirShare]
    var blockedHeirs: [BlockedHeir]
    var silsilah: [SilsilahNode]
    var adjustment: FaraidhAdjustment
    var adjustmentNoteKey: String?
    var proofKeys: [String]
    var totalDistributed: Decimal
    var remainderFraction: FaraidhFraction
    var madhhab: FaraidhMadhhab = .shafii
    var madhhabNoteKey: String? = nil
    var familyGraph: FaraidhFamilyGraph? = nil
    var classicalCase: ClassicalCase? = nil
}

struct FaraidhParticipantNames: Codable, Hashable {
    var deceasedName: String = ""
    var husbandName: String = ""
    var wifeNames: [String] = []
    var fatherName: String = ""
    var grandfatherName: String = ""
    var motherName: String = ""
    var sonNames: [String] = []
    var daughterNames: [String] = []
    var grandsonNames: [String] = []
    var granddaughterNames: [String] = []
    var fullBrotherNames: [String] = []
    var fullSisterNames: [String] = []
    var paternalBrotherNames: [String] = []
    var paternalSisterNames: [String] = []
    var maternalBrotherNames: [String] = []
    var maternalSisterNames: [String] = []
}

func resizeNameList(current: [String], count: Int) -> [String] {
    if count <= 0 { return [] }
    if current.count >= count {
        return Array(current.prefix(count))
    }
    return current + Array(repeating: "", count: count - current.count)
}

struct FaraidhNameLabels {
    static func namesForType(names: FaraidhParticipantNames, type: HeirType) -> [String] {
        switch type {
        case .husband:
            return names.husbandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [names.husbandName]
        case .wife:
            return names.wifeNames.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        case .father:
            return names.fatherName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [names.fatherName]
        case .grandfather:
            return names.grandfatherName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [names.grandfatherName]
        case .mother:
            return names.motherName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : [names.motherName]
        case .son:
            return names.sonNames
        case .daughter:
            return names.daughterNames
        case .grandson:
            return names.grandsonNames
        case .granddaughter:
            return names.granddaughterNames
        case .fullBrother:
            return names.fullBrotherNames
        case .fullSister:
            return names.fullSisterNames
        case .paternalBrother:
            return names.paternalBrotherNames
        case .paternalSister:
            return names.paternalSisterNames
        case .maternalSibling:
            return (names.maternalBrotherNames + names.maternalSisterNames).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        case .stepChild, .unbornFetus:
            return []
        }
    }
    
    static func displayList(
        type: HeirType,
        roleLabel: String,
        names: FaraidhParticipantNames,
        headCount: Int
    ) -> [String] {
        let entered = namesForType(names: names, type: type).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if !entered.isEmpty { return entered }
        return (0..<max(1, headCount)).map { index in
            if headCount > 1 { return "\(roleLabel) \(index + 1)" } else { return roleLabel }
        }
    }
}

struct MoneyInputFormatter {
    static func digitsOnly(_ input: String) -> String {
        return input.filter { $0.isNumber }
    }
    
    static func format(_ input: String) -> String {
        let digits = digitsOnly(input)
        if digits.isEmpty { return "" }
        guard let value = Int64(digits) else { return digits }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "." // Using IDR style grouping separator
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? digits
    }
    
    static func parseAmount(_ raw: String) -> Decimal {
        let digits = digitsOnly(raw)
        return Decimal(string: digits) ?? .zero
    }
}

struct FaraidhEstateCalculator {
    static func compute(input: EstateAssetInput) -> EstateComputation {
        let cash = MoneyInputFormatter.parseAmount(input.cashSavings)
        let gold = input.inputGoldByGrams ?
            (Decimal(string: input.goldWeightGrams.replacingOccurrences(of: ",", with: ".")) ?? .zero) * MoneyInputFormatter.parseAmount(input.goldPricePerGram) :
            MoneyInputFormatter.parseAmount(input.goldJewelry)
        
        let property = input.inputPropertyDetailed ?
            input.properties.reduce(Decimal.zero) { $0 + MoneyInputFormatter.parseAmount($1.value) } :
            MoneyInputFormatter.parseAmount(input.propertyValue)
            
        let business = MoneyInputFormatter.parseAmount(input.businessAssets)
        let other = MoneyInputFormatter.parseAmount(input.otherAssets)
        let debts = MoneyInputFormatter.parseAmount(input.debts)
        let funeral = MoneyInputFormatter.parseAmount(input.funeralCosts)
        let zakat = MoneyInputFormatter.parseAmount(input.unpaidZakat)
        let bequest = MoneyInputFormatter.parseAmount(input.bequestWasiat)
        
        let gross = max(.zero, cash + gold + property + business + other)
        let afterFuneral = max(.zero, gross - funeral)
        let afterDebts = max(.zero, afterFuneral - debts)
        let afterZakat = max(.zero, afterDebts - zakat)
        let maxWasiat = afterZakat / Decimal(3)
        let wasiatApplied = min(bequest, maxWasiat)
        let net = max(.zero, afterZakat - wasiatApplied)
        
        return EstateComputation(
            grossAssets: gross,
            cashComponent: cash,
            goldComponent: gold,
            propertyComponent: property,
            businessComponent: business,
            otherComponent: other,
            funeralCosts: funeral,
            debts: debts,
            unpaidZakat: zakat,
            afterFuneral: afterFuneral,
            afterDebts: afterDebts,
            afterZakat: afterZakat,
            maxWasiat: maxWasiat,
            wasiatApplied: wasiatApplied,
            netEstate: net,
            hasResidentialProperty: input.hasResidentialProperty,
            propertyNotes: input.propertyNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}
