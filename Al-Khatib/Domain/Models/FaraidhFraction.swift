import Foundation

struct FaraidhFraction: Comparable, Equatable, Hashable, Codable {
    let numerator: Int
    let denominator: Int
    
    init(numerator: Int, denominator: Int) {
        precondition(denominator > 0, "Denominator must be positive")
        self.numerator = numerator
        self.denominator = denominator
    }
    
    static func < (lhs: FaraidhFraction, rhs: FaraidhFraction) -> Bool {
        return lhs.numerator * rhs.denominator < rhs.numerator * lhs.denominator
    }
    
    static func == (lhs: FaraidhFraction, rhs: FaraidhFraction) -> Bool {
        return lhs.numerator * rhs.denominator == rhs.numerator * lhs.denominator
    }
    
    func hash(into hasher: inout Hasher) {
        let norm = normalized()
        hasher.combine(norm.numerator)
        hasher.combine(norm.denominator)
    }
    
    func normalized() -> FaraidhFraction {
        let divisor = gcd(numerator, denominator)
        let den = denominator < 0 ? -denominator : denominator
        let num = denominator < 0 ? -numerator : numerator
        return FaraidhFraction(numerator: num / divisor, denominator: den / divisor)
    }
    
    func add(_ other: FaraidhFraction) -> FaraidhFraction {
        let commonDenominator = lcm(denominator, other.denominator)
        let a = numerator * (commonDenominator / denominator)
        let b = other.numerator * (commonDenominator / other.denominator)
        return FaraidhFraction(numerator: a + b, denominator: commonDenominator).normalized()
    }
    
    func subtract(_ other: FaraidhFraction) -> FaraidhFraction {
        let commonDenominator = lcm(denominator, other.denominator)
        let a = numerator * (commonDenominator / denominator)
        let b = other.numerator * (commonDenominator / other.denominator)
        return FaraidhFraction(numerator: a - b, denominator: commonDenominator).normalized()
    }
    
    func multiply(_ other: FaraidhFraction) -> FaraidhFraction {
        return FaraidhFraction(numerator: numerator * other.numerator, denominator: denominator * other.denominator).normalized()
    }
    
    func divide(_ other: FaraidhFraction) -> FaraidhFraction {
        precondition(other.numerator != 0, "Division by zero fraction")
        return FaraidhFraction(numerator: numerator * other.denominator, denominator: denominator * other.numerator).normalized()
    }
    
    func multiplyScalar(_ count: Int) -> FaraidhFraction {
        if count <= 0 { return .zero }
        return FaraidhFraction(numerator: numerator * count, denominator: denominator).normalized()
    }
    
    func divideAmongHeads(_ heads: Int) -> FaraidhFraction {
        if heads <= 0 { return .zero }
        return FaraidhFraction(numerator: numerator, denominator: denominator * heads).normalized()
    }
    
    func toDecimal(scale: Int = 8) -> Decimal {
        let numDec = Decimal(numerator)
        let denDec = Decimal(denominator)
        return numDec / denDec
    }
    
    func toPercentage(scale: Int = 4) -> Decimal {
        let decimal = toDecimal(scale: scale + 2)
        return decimal * 100
    }
    
    func toDisplayString() -> String {
        let n = normalized()
        return "\(n.numerator)/\(n.denominator)"
    }
    
    func toCashAmount(estate: Decimal) -> Decimal {
        return estate * Decimal(numerator) / Decimal(denominator)
    }
    
    static let zero = FaraidhFraction(numerator: 0, denominator: 1)
    static let one = FaraidhFraction(numerator: 1, denominator: 1)
    
    static func of(numerator: Int, denominator: Int) -> FaraidhFraction {
        return FaraidhFraction(numerator: numerator, denominator: denominator).normalized()
    }
    
    static func sumOf(_ fractions: [FaraidhFraction]) -> FaraidhFraction {
        return fractions.reduce(.zero) { $0.add($1) }
    }
    
    static func applyAwl(shares: [(HeirType, FaraidhFraction)]) -> [(HeirType, FaraidhFraction)] {
        let total = sumOf(shares.map { $0.1 })
        if total.numerator <= total.denominator { return shares }
        return shares.map { (type, frac) in
            (type, FaraidhFraction(numerator: frac.numerator * total.denominator, denominator: frac.denominator * total.numerator).normalized())
        }
    }
    
    static func applyRadd(shares: [(HeirType, FaraidhFraction, Bool)], spouseTypes: Set<HeirType> = [.husband, .wife]) -> [(HeirType, FaraidhFraction)] {
        let total = sumOf(shares.map { $0.1 })
        if total.numerator >= total.denominator {
            return shares.map { ($0.0, $0.1) }
        }
        let surplus = FaraidhFraction(numerator: total.denominator - total.numerator, denominator: total.denominator)
        let eligible = shares.filter { !spouseTypes.contains($0.0) && $0.1.numerator > 0 }
        if eligible.isEmpty { return shares.map { ($0.0, $0.1) } }
        let eligibleTotal = sumOf(eligible.map { $0.1 })
        return shares.map { (type, frac, _) in
            if spouseTypes.contains(type) || frac.numerator == 0 {
                return (type, frac)
            } else {
                let extraProp = FaraidhFraction(numerator: frac.numerator * eligibleTotal.denominator, denominator: frac.denominator * eligibleTotal.numerator)
                let extra = FaraidhFraction(numerator: surplus.numerator * extraProp.numerator, denominator: surplus.denominator * extraProp.denominator).normalized()
                return (type, frac.add(extra).normalized())
            }
        }
    }
}

private func gcd(_ a: Int, _ b: Int) -> Int {
    var x = abs(a)
    var y = abs(b)
    while y != 0 {
        let temp = y
        y = x % y
        x = temp
    }
    return x == 0 ? 1 : x
}

private func lcm(_ a: Int, _ b: Int) -> Int {
    if a == 0 || b == 0 { return 0 }
    return abs(a * b) / gcd(a, b)
}
