import SwiftUI

struct FaraidhCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0 // 0: Form, 1: Shares, 2: Family & Proofs
    
    // Inputs
    @State private var deceasedName = ""
    @State private var gender: DeceasedGender = .male
    @State private var madhhab: FaraidhMadhhab = .shafii
    @State private var bornOutOfWedlock = false
    
    // Estate Inputs
    @State private var cashSavings = ""
    @State private var goldJewelry = ""
    @State private var propertyValue = ""
    @State private var businessAssets = ""
    @State private var otherAssets = ""
    @State private var debts = ""
    @State private var funeralCosts = ""
    @State private var unpaidZakat = ""
    @State private var wasiatBequest = ""
    
    // Heir counts
    @State private var husbandCount = 0
    @State private var wifeCount = 0
    @State private var fatherCount = 0
    @State private var grandfatherCount = 0
    @State private var motherCount = 0
    @State private var sonCount = 0
    @State private var daughterCount = 0
    @State private var grandsonCount = 0
    @State private var granddaughterCount = 0
    @State private var fullBrotherCount = 0
    @State private var fullSisterCount = 0
    @State private var paternalBrotherCount = 0
    @State private var paternalSisterCount = 0
    @State private var maternalBrotherCount = 0
    @State private var maternalSisterCount = 0
    
    // Computations
    private var result: FaraidhResult {
        let input = HeirInput(
            husbandCount: gender == .female ? husbandCount : 0,
            wifeCount: gender == .male ? wifeCount : 0,
            fatherCount: fatherCount,
            grandfatherCount: grandfatherCount,
            motherCount: motherCount,
            sonCount: sonCount,
            daughterCount: daughterCount,
            grandsonCount: grandsonCount,
            granddaughterCount: granddaughterCount,
            fullBrotherCount: fullBrotherCount,
            fullSisterCount: fullSisterCount,
            paternalBrotherCount: paternalBrotherCount,
            paternalSisterCount: paternalSisterCount,
            maternalBrotherCount: maternalBrotherCount,
            maternalSisterCount: maternalSisterCount
        )
        
        let estateInput = EstateAssetInput(
            cashSavings: cashSavings,
            goldJewelry: goldJewelry,
            goldWeightGrams: "",
            goldPricePerGram: "",
            inputGoldByGrams: false,
            propertyValue: propertyValue,
            properties: [],
            inputPropertyDetailed: false,
            businessAssets: businessAssets,
            otherAssets: otherAssets,
            hasResidentialProperty: false,
            propertyNotes: "",
            debts: debts,
            funeralCosts: funeralCosts,
            unpaidZakat: unpaidZakat,
            bequestWasiat: wasiatBequest
        )
        
        let estateCalc = FaraidhEstateCalculator.compute(input: estateInput)
        let profile = DeceasedProfile(
            gender: gender,
            netEstate: estateCalc.netEstate,
            name: deceasedName.trimmingCharacters(in: .whitespacesAndNewlines),
            estate: estateCalc,
            madhhab: madhhab,
            bornOutOfWedlock: bornOutOfWedlock
        )
        
        return FaraidhEngine.calculate(profile: profile, input: input, madhhab: madhhab)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white))
                }
                
                Text("Inheritance Calculator")
                    .font(.title3.bold())
                    .foregroundColor(Color.Token.deepEmerald)
                
                Spacer()
                
                Button(action: resetInputs) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.Token.deepEmerald)
                }
                .padding(.trailing, 8)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Tab Selector
            HStack(spacing: 0) {
                tabButton(title: "Form", index: 0)
                tabButton(title: "Shares", index: 1)
                tabButton(title: "Proofs", index: 2)
            }
            .background(Color.white)
            .padding(.vertical, 8)
            
            Divider()
            
            // Contents
            ZStack {
                Color.Token.offWhite.ignoresSafeArea()
                
                if selectedTab == 0 {
                    formTab
                } else if selectedTab == 1 {
                    sharesTab
                } else {
                    proofsTab
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(selectedTab == index ? .bold : .medium))
                    .foregroundColor(selectedTab == index ? Color.Token.deepEmerald : .secondary)
                
                Rectangle()
                    .fill(selectedTab == index ? Color.Token.deepEmerald : Color.clear)
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Form Tab
    private var formTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Deceased Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Deceased Profile")
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    TextField("Deceased Name", text: $deceasedName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Gender").font(.caption).foregroundColor(.secondary)
                            Picker("Gender", selection: $gender) {
                                Text("Male").tag(DeceasedGender.male)
                                Text("Female").tag(DeceasedGender.female)
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Madhhab").font(.caption).foregroundColor(.secondary)
                            Picker("Madhhab", selection: $madhhab) {
                                Text("Shafi'i").tag(FaraidhMadhhab.shafii)
                                Text("Hanafi").tag(FaraidhMadhhab.hanafi)
                                Text("Maliki").tag(FaraidhMadhhab.maliki)
                                Text("Hanbali").tag(FaraidhMadhhab.hanbali)
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        }
                    }
                    
                    Toggle("Deceased Born Out of Wedlock", isOn: $bornOutOfWedlock)
                        .tint(Color.Token.deepEmerald)
                        .font(.subheadline)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                // Estate / Net Assets Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Estate & Deductions")
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    VStack(spacing: 8) {
                        moneyTextField("Cash/Savings", text: $cashSavings)
                        moneyTextField("Gold Assets", text: $goldJewelry)
                        moneyTextField("Property Value", text: $propertyValue)
                        moneyTextField("Business Assets", text: $businessAssets)
                        moneyTextField("Other Assets", text: $otherAssets)
                        
                        Divider().padding(.vertical, 4)
                        
                        moneyTextField("Funeral Costs", text: $funeralCosts)
                        moneyTextField("Debts / Liabilities", text: $debts)
                        moneyTextField("Unpaid Zakat", text: $unpaidZakat)
                        moneyTextField("Bequest (Wasiat)", text: $wasiatBequest)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                // Heirs checklist
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Surviving Heirs")
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    VStack(spacing: 10) {
                        if gender == .female {
                            heirStepper("Husband", count: $husbandCount, range: 0...1)
                        } else {
                            heirStepper("Wives", count: $wifeCount, range: 0...4)
                        }
                        
                        heirStepper("Father", count: $fatherCount, range: 0...1)
                        heirStepper("Mother", count: $motherCount, range: 0...1)
                        heirStepper("Grandfather", count: $grandfatherCount, range: 0...1)
                        
                        Divider().padding(.vertical, 4)
                        
                        heirStepper("Sons", count: $sonCount, range: 0...20)
                        heirStepper("Daughters", count: $daughterCount, range: 0...20)
                        heirStepper("Grandsons (via Son)", count: $grandsonCount, range: 0...20)
                        heirStepper("Granddaughters (via Son)", count: $granddaughterCount, range: 0...20)
                        
                        Divider().padding(.vertical, 4)
                        
                        heirStepper("Full Brothers", count: $fullBrotherCount, range: 0...20)
                        heirStepper("Full Sisters", count: $fullSisterCount, range: 0...20)
                        heirStepper("Paternal Brothers", count: $paternalBrotherCount, range: 0...20)
                        heirStepper("Paternal Sisters", count: $paternalSisterCount, range: 0...20)
                        heirStepper("Maternal Brothers", count: $maternalBrotherCount, range: 0...20)
                        heirStepper("Maternal Sisters", count: $maternalSisterCount, range: 0...20)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                Button(action: { selectedTab = 1 }) {
                    Text("Calculate Inheritance Shares")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.Token.deepEmerald)
                        .cornerRadius(12)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }
    
    private func moneyTextField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            TextField("0", text: Binding(
                get: { text.wrappedValue },
                set: { text.wrappedValue = MoneyInputFormatter.format($0) }
            ))
            .keyboardType(.numberPad)
            .multilineTextAlignment(.trailing)
            .frame(width: 140)
            .textFieldStyle(.roundedBorder)
        }
    }
    
    private func heirStepper(_ label: String, count: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Stepper("\(count.wrappedValue)", value: count, in: range)
                .labelsHidden()
            Text("\(count.wrappedValue)")
                .font(.subheadline.bold())
                .frame(width: 30, alignment: .trailing)
        }
    }
    
    // MARK: - Shares Tab
    private var sharesTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Estate Summary Card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Estate Summary")
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    let comp = result.deceased.estate ?? FaraidhEstateCalculator.compute(input: EstateAssetInput())
                    
                    summaryRow(label: "Gross Assets", amount: comp.grossAssets)
                    summaryRow(label: "Funeral Costs", amount: comp.funeralCosts, isMinus: true)
                    summaryRow(label: "Debts / Liabilities", amount: comp.debts, isMinus: true)
                    summaryRow(label: "Unpaid Zakat", amount: comp.unpaidZakat, isMinus: true)
                    summaryRow(label: "Bequest (Wasiat)", amount: comp.wasiatApplied, isMinus: true)
                    
                    Divider().padding(.vertical, 4)
                    
                    HStack {
                        Text("Net Inheritable Estate")
                            .font(.subheadline.bold())
                            .foregroundColor(Color.Token.deepEmerald)
                        Spacer()
                        Text("IDR \(formatCurrency(comp.netEstate))")
                            .font(.headline.bold())
                            .foregroundColor(Color.Token.deepEmerald)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                // Classical Case Badge
                if let classical = result.classicalCase {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(Color.Token.gold)
                        Text("Detected Case: \(classicalCaseName(classical))")
                            .font(.subheadline.bold())
                            .foregroundColor(Color.Token.deepEmerald)
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.Token.gold.opacity(0.12))
                    .cornerRadius(10)
                }
                
                // Inheriting shares
                VStack(alignment: .leading, spacing: 12) {
                    Text("Heir Distributions")
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    if result.activeShares.isEmpty {
                        Text("No active inheriting heirs. Total will fallback to Baitul Mal.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(result.activeShares, id: \.self) { share in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(share.isAsabah ? Color.orange : Color.Token.deepEmerald)
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 6)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(heirNameLabel(share.type))
                                        .font(.subheadline.bold())
                                        .foregroundColor(.primary)
                                    Text("\(share.headCount) Person\(share.headCount > 1 ? "s" : "") \u{2022} \(share.isAsabah ? "Asabah (Residue)" : "Fixed Share")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("IDR \(formatCurrency(share.cashAmount))")
                                        .font(.subheadline.bold())
                                        .foregroundColor(Color.Token.deepEmerald)
                                    Text("\(share.fraction.toDisplayString()) (\(String(format: "%.1f", Double(truncating: share.percentage as NSNumber)))%)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                // Adjustment Note
                if result.adjustment != .none {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.adjustment == .awl ? "Aul Deficit Adjustment" : "Radd Surplus Adjustment")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text(result.adjustment == .awl ?
                                 "Deficit in fixed shares resolved by increasing the denominator." :
                                 "Surplus residue distributed back to eligible Quranic heirs.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }
    
    private func summaryRow(label: String, amount: Decimal, isMinus: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(isMinus ? "-" : "")IDR \(formatCurrency(amount))")
                .font(.subheadline)
                .foregroundColor(isMinus ? .red : .primary)
        }
    }
    
    // MARK: - Proofs Tab
    private var proofsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Blocked / Excluded Heirs
                VStack(alignment: .leading, spacing: 12) {
                    Text("Blocked / Excluded Heirs")
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    if result.blockedHeirs.isEmpty {
                        Text("No heirs were blocked or excluded.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(result.blockedHeirs, id: \.self) { blocked in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(heirNameLabel(blocked.type))
                                        .font(.subheadline.bold())
                                    Text("\(blocked.headCount) Person\(blocked.headCount > 1 ? "s" : "")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(blockingReasonText(blocked.reason))
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .cornerRadius(6)
                            }
                            Divider()
                        }
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                // Silsilah Family Tree Nodes list
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kinship Hierarchy (Silsilah)")
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    ForEach(result.silsilah) { node in
                        HStack {
                            let indent = CGFloat(max(0, node.generationLevel + 2)) * 14.0
                            Spacer().frame(width: indent)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(nodeLabel(node.type))
                                        .font(.subheadline.weight(node.id == "deceased" ? .bold : .semibold))
                                        .foregroundColor(node.id == "deceased" ? Color.Token.deepEmerald : .primary)
                                    
                                    if node.inherits {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                    } else if node.blocked {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                                
                                if let frac = node.shareFraction, let pct = node.sharePercentage {
                                    Text("Indiv Share: \(frac) (\(pct))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }
    
    // MARK: - Helpers
    private func resetInputs() {
        deceasedName = ""
        gender = .male
        madhhab = .shafii
        bornOutOfWedlock = false
        cashSavings = ""
        goldJewelry = ""
        propertyValue = ""
        businessAssets = ""
        otherAssets = ""
        debts = ""
        funeralCosts = ""
        unpaidZakat = ""
        wasiatBequest = ""
        husbandCount = 0
        wifeCount = 0
        fatherCount = 0
        grandfatherCount = 0
        motherCount = 0
        sonCount = 0
        daughterCount = 0
        grandsonCount = 0
        granddaughterCount = 0
        fullBrotherCount = 0
        fullSisterCount = 0
        paternalBrotherCount = 0
        paternalSisterCount = 0
        maternalBrotherCount = 0
        maternalSisterCount = 0
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "0"
    }
    
    private func heirNameLabel(_ type: HeirType) -> String {
        switch type {
        case .husband: return "Husband"
        case .wife: return "Wife"
        case .father: return "Father"
        case .grandfather: return "Grandfather"
        case .mother: return "Mother"
        case .son: return "Son"
        case .daughter: return "Daughter"
        case .grandson: return "Grandson (via Son)"
        case .granddaughter: return "Granddaughter (via Son)"
        case .fullBrother: return "Full Brother"
        case .fullSister: return "Full Sister"
        case .paternalBrother: return "Paternal Brother"
        case .paternalSister: return "Paternal Sister"
        case .maternalSibling: return "Maternal Sibling"
        case .stepChild: return "Baitul Mal / Excluded Kindred"
        case .unbornFetus: return "Unborn Fetus"
        }
    }
    
    private func nodeLabel(_ type: HeirType) -> String {
        if type == .son && deceasedName.isEmpty == false {
            return "Deceased: \(deceasedName)"
        }
        return heirNameLabel(type)
    }
    
    private func blockingReasonText(_ reason: BlockingReasonKey) -> String {
        switch reason {
        case .bySon: return "Blocked by Son"
        case .byChildren: return "Blocked by Child"
        case .byFather: return "Blocked by Father"
        case .byGrandfather: return "Blocked by Grandfather"
        case .byGrandchildrenSubstitute: return "Excluded"
        case .genderMismatch: return "Gender Mismatch"
        case .noShareRemainder: return "No Share Remainder"
        case .outOfWedlock: return "Born Out of Wedlock"
        case .homicide: return "Excluded by Homicide"
        case .differenceOfReligion: return "Difference of Religion"
        case .simultaneousDeath: return "Simultaneous Death"
        }
    }
    
    private func classicalCaseName(_ value: ClassicalCase) -> String {
        switch value {
        case .alMinbariyah: return "Al-Minbariyah"
        case .alAkdariyah: return "Al-Akdariyah"
        case .alMarwaniyah: return "Al-Marwaniyah"
        case .umariyatain: return "Al-Umariyatain"
        }
    }
}
