import Foundation

struct DzawilArhamResolver {
    struct FallbackResult {
        let activeShares: [HeirShare]
        let proofKeys: [String]
        let noteKey: String
    }
    
    static func resolve(estate: Decimal, input: HeirInput) -> FallbackResult {
        let shares = [
            HeirShare(
                type: .stepChild,
                headCount: 1,
                fraction: .one,
                percentage: Decimal(100),
                cashAmount: estate,
                isAsabah: false,
                proofKeys: ["proof_baitul_mal"]
            )
        ]
        return FallbackResult(activeShares: shares, proofKeys: ["proof_baitul_mal"], noteKey: "proof_baitul_mal_desc")
    }
}
