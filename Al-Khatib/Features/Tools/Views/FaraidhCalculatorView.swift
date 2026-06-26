import SwiftUI

struct FaraidhCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0 // 0: Form, 1: Shares, 2: Family & Proofs
    
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
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
                
                Text(languageManager.localize("tool_faraidh"))
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
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // Tab Selector
            HStack(spacing: 0) {
                tabButton(title: languageManager.localize("faraidh_tab_form"), index: 0)
                tabButton(title: languageManager.localize("faraidh_tab_shares"), index: 1)
                tabButton(title: languageManager.localize("faraidh_tab_proofs"), index: 2)
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
                    Text(languageManager.localize("faraidh_profile"))
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    TextField(languageManager.localize("faraidh_name"), text: $deceasedName)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(languageManager.localize("faraidh_gender")).font(.caption).foregroundColor(.secondary)
                            Picker("Gender", selection: $gender) {
                                Text(languageManager.localize("faraidh_male")).tag(DeceasedGender.male)
                                Text(languageManager.localize("faraidh_female")).tag(DeceasedGender.female)
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(languageManager.localize("faraidh_madhhab")).font(.caption).foregroundColor(.secondary)
                            Picker("Madhhab", selection: $madhhab) {
                                Text(languageManager.localize("faraidh_shafii")).tag(FaraidhMadhhab.shafii)
                                Text(languageManager.localize("faraidh_hanafi")).tag(FaraidhMadhhab.hanafi)
                                Text(languageManager.localize("faraidh_maliki")).tag(FaraidhMadhhab.maliki)
                                Text(languageManager.localize("faraidh_hanbali")).tag(FaraidhMadhhab.hanbali)
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        }
                    }
                    
                    Toggle(languageManager.localize("faraidh_out_wedlock"), isOn: $bornOutOfWedlock)
                        .tint(Color.Token.deepEmerald)
                        .font(.subheadline)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                // Estate / Net Assets Info
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localize("faraidh_estate"))
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    VStack(spacing: 8) {
                        moneyTextField(languageManager.localize("faraidh_cash"), text: $cashSavings)
                        moneyTextField(languageManager.localize("faraidh_gold"), text: $goldJewelry)
                        moneyTextField(languageManager.localize("faraidh_property"), text: $propertyValue)
                        moneyTextField(languageManager.localize("faraidh_business"), text: $businessAssets)
                        moneyTextField(languageManager.localize("faraidh_other"), text: $otherAssets)
                        
                        Divider().padding(.vertical, 4)
                        
                        moneyTextField(languageManager.localize("faraidh_funeral"), text: $funeralCosts)
                        moneyTextField(languageManager.localize("faraidh_debts"), text: $debts)
                        moneyTextField(languageManager.localize("faraidh_zakat"), text: $unpaidZakat)
                        moneyTextField(languageManager.localize("faraidh_wasiat"), text: $wasiatBequest)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                // Heirs checklist
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localize("faraidh_heirs"))
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    VStack(spacing: 10) {
                        if gender == .female {
                            heirStepper(languageManager.localize("faraidh_heir_husband"), count: $husbandCount, range: 0...1)
                        } else {
                            heirStepper(languageManager.localize("faraidh_heir_wives"), count: $wifeCount, range: 0...4)
                        }
                        
                        heirStepper(languageManager.localize("faraidh_heir_father"), count: $fatherCount, range: 0...1)
                        heirStepper(languageManager.localize("faraidh_heir_mother"), count: $motherCount, range: 0...1)
                        heirStepper(languageManager.localize("faraidh_heir_grandfather"), count: $grandfatherCount, range: 0...1)
                        
                        Divider().padding(.vertical, 4)
                        
                        heirStepper(languageManager.localize("faraidh_heir_sons"), count: $sonCount, range: 0...20)
                        heirStepper(languageManager.localize("faraidh_heir_daughters"), count: $daughterCount, range: 0...20)
                        heirStepper(languageManager.localize("faraidh_heir_grandsons"), count: $grandsonCount, range: 0...20)
                        heirStepper(languageManager.localize("faraidh_heir_granddaughters"), count: $granddaughterCount, range: 0...20)
                        
                        Divider().padding(.vertical, 4)
                        
                        heirStepper(languageManager.localize("faraidh_heir_full_brothers"), count: $fullBrotherCount, range: 0...20)
                        heirStepper(languageManager.localize("faraidh_heir_full_sisters"), count: $fullSisterCount, range: 0...20)
                        heirStepper(languageManager.localize("faraidh_heir_paternal_brothers"), count: $paternalBrotherCount, range: 0...20)
                        heirStepper(languageManager.localize("faraidh_heir_paternal_sisters"), count: $paternalSisterCount, range: 0...20)
                        heirStepper(languageManager.localize("faraidh_heir_maternal_brothers"), count: $maternalBrotherCount, range: 0...20)
                        heirStepper(languageManager.localize("faraidh_heir_maternal_sisters"), count: $maternalSisterCount, range: 0...20)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                Button(action: { selectedTab = 1 }) {
                    Text(languageManager.localize("faraidh_btn_calc"))
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
                    Text(languageManager.localize("faraidh_estate_summary"))
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    let comp = result.deceased.estate ?? FaraidhEstateCalculator.compute(input: EstateAssetInput())
                    
                    summaryRow(label: languageManager.localize("faraidh_gross_assets"), amount: comp.grossAssets)
                    summaryRow(label: languageManager.localize("faraidh_funeral"), amount: comp.funeralCosts, isMinus: true)
                    summaryRow(label: languageManager.localize("faraidh_debts"), amount: comp.debts, isMinus: true)
                    summaryRow(label: languageManager.localize("faraidh_zakat"), amount: comp.unpaidZakat, isMinus: true)
                    summaryRow(label: languageManager.localize("faraidh_wasiat"), amount: comp.wasiatApplied, isMinus: true)
                    
                    Divider().padding(.vertical, 4)
                    
                    HStack {
                        Text(languageManager.localize("faraidh_net_estate"))
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
                        Text(String(format: languageManager.localize("faraidh_case_format"), classicalCaseName(classical)))
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
                    Text(languageManager.localize("faraidh_distributions"))
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    if result.activeShares.isEmpty {
                        Text(languageManager.localize("faraidh_fallback_baitulmal"))
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
                                    
                                    let countLabel = share.headCount > 1 ? languageManager.localize("faraidh_heir_count_plural") : languageManager.localize("faraidh_heir_count_singular")
                                    let shareTypeLabel = share.isAsabah ? languageManager.localize("faraidh_type_asabah") : languageManager.localize("faraidh_type_fixed")
                                    Text("\(share.headCount) \(countLabel) \u{2022} \(shareTypeLabel)")
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
                            Text(result.adjustment == .awl ? languageManager.localize("faraidh_aul") : languageManager.localize("faraidh_radd"))
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text(result.adjustment == .awl ?
                                 languageManager.localize("faraidh_aul_desc") :
                                 languageManager.localize("faraidh_radd_desc"))
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
                    Text(languageManager.localize("faraidh_blocked_heirs"))
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    if result.blockedHeirs.isEmpty {
                        Text(languageManager.localize("faraidh_no_blocked"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(result.blockedHeirs, id: \.self) { blocked in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(heirNameLabel(blocked.type))
                                        .font(.subheadline.bold())
                                    let personLabel = blocked.headCount > 1 ? languageManager.localize("faraidh_heir_count_plural") : languageManager.localize("faraidh_heir_count_singular")
                                    Text("\(blocked.headCount) \(personLabel)")
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
                    Text(languageManager.localize("faraidh_silsilah"))
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
                                    Text("\(languageManager.localize("faraidh_indiv_share")): \(frac) (\(pct))")
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
        case .husband: return languageManager.localize("faraidh_heir_husband")
        case .wife: return languageManager.localize("faraidh_heir_wives")
        case .father: return languageManager.localize("faraidh_heir_father")
        case .grandfather: return languageManager.localize("faraidh_heir_grandfather")
        case .mother: return languageManager.localize("faraidh_heir_mother")
        case .son: return languageManager.localize("faraidh_heir_sons")
        case .daughter: return languageManager.localize("faraidh_heir_daughters")
        case .grandson: return languageManager.localize("faraidh_heir_grandsons")
        case .granddaughter: return languageManager.localize("faraidh_heir_granddaughters")
        case .fullBrother: return languageManager.localize("faraidh_heir_full_brothers")
        case .fullSister: return languageManager.localize("faraidh_heir_full_sisters")
        case .paternalBrother: return languageManager.localize("faraidh_heir_paternal_brothers")
        case .paternalSister: return languageManager.localize("faraidh_heir_paternal_sisters")
        case .maternalSibling: return languageManager.localize("faraidh_heir_maternal_sibling")
        case .stepChild: return languageManager.localize("faraidh_heir_baitul_mal_or_excluded")
        case .unbornFetus: return languageManager.localize("faraidh_heir_unborn_fetus")
        }
    }
    
    private func nodeLabel(_ type: HeirType) -> String {
        if type == .son && deceasedName.isEmpty == false {
            return "\(languageManager.localize("faraidh_deceased")): \(deceasedName)"
        }
        return heirNameLabel(type)
    }
    
    private func blockingReasonText(_ reason: BlockingReasonKey) -> String {
        switch reason {
        case .bySon: return languageManager.localize("faraidh_reason_by_son")
        case .byChildren: return languageManager.localize("faraidh_reason_by_children")
        case .byFather: return languageManager.localize("faraidh_reason_by_father")
        case .byGrandfather: return languageManager.localize("faraidh_reason_by_grandfather")
        case .byGrandchildrenSubstitute: return languageManager.localize("faraidh_reason_excluded")
        case .genderMismatch: return languageManager.localize("faraidh_reason_gender_mismatch")
        case .noShareRemainder: return languageManager.localize("faraidh_reason_no_remainder")
        case .outOfWedlock: return languageManager.localize("faraidh_reason_out_of_wedlock")
        case .homicide: return languageManager.localize("faraidh_reason_homicide")
        case .differenceOfReligion: return languageManager.localize("faraidh_reason_religion")
        case .simultaneousDeath: return languageManager.localize("faraidh_reason_simultaneous")
        }
    }
    
    private func classicalCaseName(_ value: ClassicalCase) -> String {
        switch value {
        case .alMinbariyah: return languageManager.localize("faraidh_case_minbariyah")
        case .alAkdariyah: return languageManager.localize("faraidh_case_akdariyah")
        case .alMarwaniyah: return languageManager.localize("faraidh_case_marwaniyah")
        case .umariyatain: return languageManager.localize("faraidh_case_umariyatain")
        }
    }
}
