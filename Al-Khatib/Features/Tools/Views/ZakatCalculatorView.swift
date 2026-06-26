import SwiftUI

struct ZakatCalculatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0 // 0: Zakat Maal, 1: Zakat Fitrah
    
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    // Zakat Maal Inputs
    @State private var cashSavings = ""
    @State private var goldWeightGrams = ""
    @State private var silverWeightGrams = ""
    @State private var investmentsValue = ""
    @State private var debtsValue = ""
    @State private var customGoldPrice = ""
    
    // Zakat Fitrah Inputs
    @State private var familyCount = 1
    @State private var ricePricePerKg = "15000" // Default IDR rice price per kg
    
    // Live Gold Quote
    @State private var goldQuote: GoldPriceQuote? = nil
    @State private var isFetchingPrice = false
    
    private var goldPricePerGram: Double {
        if let custom = Double(customGoldPrice.filter { $0.isNumber }), custom > 0 {
            return custom
        }
        return goldQuote?.goldPerGramIdr ?? 1000000.0 // Default 1M IDR if not fetched
    }
    
    private var silverPricePerGram: Double {
        return goldQuote?.silverPerGramIdr ?? ZakatCalculator.silverPriceFromGold(goldPricePerGram: goldPricePerGram)
    }
    
    private var maalResult: ZakatMaalCalculationResult {
        let cash = Double(cashSavings.filter { $0.isNumber }) ?? 0.0
        let gold = Double(goldWeightGrams.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let silver = Double(silverWeightGrams.replacingOccurrences(of: ",", with: ".")) ?? 0.0
        let inv = Double(investmentsValue.filter { $0.isNumber }) ?? 0.0
        let debts = Double(debtsValue.filter { $0.isNumber }) ?? 0.0
        
        return ZakatCalculator.calculate(
            cash: cash,
            goldGrams: gold,
            silverGrams: silver,
            investments: inv,
            debts: debts,
            goldPricePerGram: goldPricePerGram,
            silverPricePerGram: silverPricePerGram
        )
    }
    
    private var fitrahResult: ZakatFitrahCalculationResult {
        let price = Double(ricePricePerKg.filter { $0.isNumber }) ?? 0.0
        return ZakatCalculator.calculateFitrah(familyMembers: familyCount, staplePricePerKg: price)
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
                
                Text(languageManager.localize("tool_zakat"))
                    .font(.title3.bold())
                    .foregroundColor(Color.Token.deepEmerald)
                
                Spacer()
                
                if isFetchingPrice {
                    ProgressView()
                        .tint(Color.Token.deepEmerald)
                } else {
                    Button(action: { Task { await fetchLivePrice() } }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.Token.deepEmerald)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Tab Selector
            HStack(spacing: 0) {
                tabButton(title: languageManager.localize("zakat_maal"), index: 0)
                tabButton(title: languageManager.localize("zakat_fitrah"), index: 1)
            }
            .background(Color.white)
            .padding(.vertical, 8)
            
            Divider()
            
            // Contents
            ZStack {
                Color.Token.offWhite.ignoresSafeArea()
                
                if selectedTab == 0 {
                    maalTab
                } else {
                    fitrahTab
                }
            }
        }
        .onAppear {
            Task { await fetchLivePrice() }
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
    
    // MARK: - Zakat Maal Tab
    private var maalTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Live Gold Price HUD
                HStack {
                    Image(systemName: "circle.grid.hex.fill")
                        .foregroundColor(Color.Token.gold)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(languageManager.localize("zakat_live_gold"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let quote = goldQuote {
                            Text("IDR \(formatCurrency(Decimal(quote.goldPerGramIdr))) / gram")
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            Text(String(format: languageManager.localize("zakat_source_format"), quote.sourceLabel))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        } else {
                            Text(String(format: languageManager.localize("zakat_gold_default_format"), formatCurrency(Decimal(goldPricePerGram))))
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(14)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                // Form Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localize("zakat_assets_liabilities"))
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    VStack(spacing: 8) {
                        moneyTextField(languageManager.localize("zakat_cash_savings"), text: $cashSavings)
                        
                        HStack {
                            Text(languageManager.localize("zakat_gold_owned"))
                                .font(.subheadline)
                            Spacer()
                            TextField("0.0", text: $goldWeightGrams)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        HStack {
                            Text(languageManager.localize("zakat_silver_owned"))
                                .font(.subheadline)
                            Spacer()
                            TextField("0.0", text: $silverWeightGrams)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        moneyTextField(languageManager.localize("zakat_investments"), text: $investmentsValue)
                        moneyTextField(languageManager.localize("zakat_debts"), text: $debtsValue)
                        
                        Divider().padding(.vertical, 4)
                        
                        moneyTextField(languageManager.localize("zakat_custom_gold"), text: $customGoldPrice)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                // Calculations Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localize("zakat_maal_results"))
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    let res = maalResult
                    
                    HStack {
                        Text(languageManager.localize("zakat_net_wealth"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("IDR \(formatCurrency(Decimal(res.zakatableWealth)))")
                            .font(.subheadline.bold())
                    }
                    
                    HStack {
                        Text(languageManager.localize("zakat_nisab_limit"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("IDR \(formatCurrency(Decimal(res.nisabGoldValue)))")
                            .font(.subheadline)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text(languageManager.localize("zakat_status"))
                            .font(.subheadline.bold())
                        Spacer()
                        if res.meetsNisab {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text(languageManager.localize("zakat_meets_nisab"))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.green)
                            }
                        } else {
                            Text(languageManager.localize("zakat_no_nisab"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text(languageManager.localize("zakat_due"))
                            .font(.title3.bold())
                            .foregroundColor(Color.Token.deepEmerald)
                        Spacer()
                        Text("IDR \(formatCurrency(Decimal(res.zakatDue)))")
                            .font(.title3.bold())
                            .foregroundColor(Color.Token.deepEmerald)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                .padding(.bottom, 24)
            }
            .padding(.horizontal)
            .padding(.top, 12)
        }
    }
    
    // MARK: - Zakat Fitrah Tab
    private var fitrahTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Form Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localize("zakat_fitrah_specs"))
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    HStack {
                        Text(languageManager.localize("zakat_family_members"))
                            .font(.subheadline)
                        Spacer()
                        Stepper("\(familyCount)", value: $familyCount, in: 1...30)
                            .labelsHidden()
                        Text("\(familyCount)")
                            .font(.subheadline.bold())
                            .frame(width: 24, alignment: .trailing)
                    }
                    
                    moneyTextField(languageManager.localize("zakat_staple_price"), text: $ricePricePerKg)
                    
                    HStack {
                        Text(languageManager.localize("zakat_staple_weight"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("2.5 kg")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
                
                // Calculations Card
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localize("zakat_fitrah_results"))
                        .font(.headline)
                        .foregroundColor(Color.Token.deepEmerald)
                    
                    let res = fitrahResult
                    
                    HStack {
                        Text(languageManager.localize("zakat_total_staple"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f kg", res.totalStapleKilograms))
                            .font(.subheadline.bold())
                    }
                    
                    Divider()
                    
                    HStack {
                        Text(languageManager.localize("zakat_fitrah_due"))
                            .font(.title3.bold())
                            .foregroundColor(Color.Token.deepEmerald)
                        Spacer()
                        Text("IDR \(formatCurrency(Decimal(res.zakatDue)))")
                            .font(.title3.bold())
                            .foregroundColor(Color.Token.deepEmerald)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
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
    
    private func fetchLivePrice() async {
        isFetchingPrice = true
        defer { isFetchingPrice = false }
        if let quote = await GoldPriceRepository.shared.fetchQuote(currency: "IDR") {
            goldQuote = quote
        }
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
}
