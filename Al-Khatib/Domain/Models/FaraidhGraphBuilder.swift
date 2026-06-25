import Foundation

struct FaraidhGraphBuilder {
    static func build(
        profile: DeceasedProfile,
        input: HeirInput,
        activeShares: [HeirShare],
        blockedHeirs: [BlockedHeir]
    ) -> FaraidhFamilyGraph {
        var nodes: [String: FaraidhGraphNode] = [:]
        var edges: [FaraidhGraphEdge] = []
        
        let rootId = "deceased_root"
        let deceasedName = profile.name.isEmpty ? "Deceased" : profile.name
        nodes[rootId] = FaraidhGraphNode(
            id: rootId,
            displayName: deceasedName,
            generationLevel: 0,
            relationType: nil,
            status: .active,
            visualColorHex: "#1E293B"
        )
        
        // 1. Spouses (Generation 0)
        if input.husbandCount > 0 {
            let id = "husband_1"
            let share = activeShares.first { $0.type == .husband }
            nodes[id] = FaraidhGraphNode(
                id: id,
                displayName: "Husband",
                generationLevel: 0,
                relationType: .husband,
                status: share != nil ? .active : .mahjubHirman,
                baseShareFraction: share?.fraction.toDisplayString(),
                finalPercentage: Double(truncating: (share?.percentage ?? .zero) as NSNumber),
                cashValue: share?.cashAmount ?? .zero,
                visualColorHex: share != nil ? "#10B981" : "#EF4444"
            )
            edges.append(FaraidhGraphEdge(fromId: rootId, toId: id, type: .marriage))
        }
        
        for i in 1...input.wifeCount {
            if i <= 0 { continue }
            let id = "wife_\(i)"
            let share = activeShares.first { $0.type == .wife }
            let wifePct = Double(truncating: ((share?.percentage ?? .zero) / Decimal(input.wifeCount)) as NSNumber)
            let wifeCash = (share?.cashAmount ?? .zero) / Decimal(input.wifeCount)
            nodes[id] = FaraidhGraphNode(
                id: id,
                displayName: "Wife \(i)",
                generationLevel: 0,
                relationType: .wife,
                status: share != nil ? .active : .mahjubHirman,
                baseShareFraction: share?.fraction.toDisplayString(),
                finalPercentage: wifePct,
                cashValue: wifeCash,
                visualColorHex: share != nil ? "#10B981" : "#EF4444"
            )
            edges.append(FaraidhGraphEdge(fromId: rootId, toId: id, type: .marriage))
        }
        
        // 2. Parents (Generation +1)
        if input.fatherCount > 0 {
            let id = "father_1"
            let share = activeShares.first { $0.type == .father }
            let blocked = blockedHeirs.first { $0.type == .father }
            let status: GraphNodeStatus = {
                if blocked?.reason == .outOfWedlock { return .excludedByLaw }
                if blocked != nil { return .mahjubHirman }
                return .active
            }()
            nodes[id] = FaraidhGraphNode(
                id: id,
                displayName: "Father",
                generationLevel: 1,
                relationType: .father,
                status: status,
                baseShareFraction: share?.fraction.toDisplayString(),
                finalPercentage: Double(truncating: (share?.percentage ?? .zero) as NSNumber),
                cashValue: share?.cashAmount ?? .zero,
                disqualificationReasonId: blocked?.reason.rawValue.lowercased(),
                visualColorHex: status == .active ? "#10B981" : "#EF4444"
            )
            edges.append(FaraidhGraphEdge(fromId: id, toId: rootId, type: .parentChild))
        }
        
        if input.grandfatherCount > 0 {
            let id = "grandfather_1"
            let share = activeShares.first { $0.type == .grandfather }
            let blocked = blockedHeirs.first { $0.type == .grandfather }
            let status: GraphNodeStatus = {
                if blocked?.reason == .outOfWedlock { return .excludedByLaw }
                if blocked != nil { return .mahjubHirman }
                return .active
            }()
            nodes[id] = FaraidhGraphNode(
                id: id,
                displayName: "Grandfather",
                generationLevel: 2,
                relationType: .grandfather,
                status: status,
                baseShareFraction: share?.fraction.toDisplayString(),
                finalPercentage: Double(truncating: (share?.percentage ?? .zero) as NSNumber),
                cashValue: share?.cashAmount ?? .zero,
                disqualificationReasonId: blocked?.reason.rawValue.lowercased(),
                visualColorHex: status == .active ? "#10B981" : "#EF4444"
            )
            let parentId = input.fatherCount > 0 ? "father_1" : rootId
            edges.append(FaraidhGraphEdge(fromId: id, toId: parentId, type: .parentChild))
        }
        
        if input.motherCount > 0 {
            let id = "mother_1"
            let share = activeShares.first { $0.type == .mother }
            nodes[id] = FaraidhGraphNode(
                id: id,
                displayName: "Mother",
                generationLevel: 1,
                relationType: .mother,
                status: share != nil ? .active : .mahjubHirman,
                baseShareFraction: share?.fraction.toDisplayString(),
                finalPercentage: Double(truncating: (share?.percentage ?? .zero) as NSNumber),
                cashValue: share?.cashAmount ?? .zero,
                visualColorHex: share != nil ? "#10B981" : "#EF4444"
            )
            edges.append(FaraidhGraphEdge(fromId: id, toId: rootId, type: .parentChild))
        }
        
        // 3. Children (Generation -1)
        for i in 1...input.sonCount {
            if i <= 0 { continue }
            let id = "son_\(i)"
            let share = activeShares.first { $0.type == .son }
            let sonPct = Double(truncating: ((share?.percentage ?? .zero) / Decimal(input.sonCount)) as NSNumber)
            let sonCash = (share?.cashAmount ?? .zero) / Decimal(input.sonCount)
            nodes[id] = FaraidhGraphNode(
                id: id,
                displayName: "Son \(i)",
                generationLevel: -1,
                relationType: .son,
                status: share != nil ? .active : .mahjubHirman,
                baseShareFraction: share?.fraction.toDisplayString(),
                finalPercentage: sonPct,
                cashValue: sonCash,
                visualColorHex: share != nil ? "#10B981" : "#EF4444"
            )
            edges.append(FaraidhGraphEdge(fromId: rootId, toId: id, type: .parentChild))
        }
        
        for i in 1...input.daughterCount {
            if i <= 0 { continue }
            let id = "daughter_\(i)"
            let share = activeShares.first { $0.type == .daughter }
            let daughterPct = Double(truncating: ((share?.percentage ?? .zero) / Decimal(input.daughterCount)) as NSNumber)
            let daughterCash = (share?.cashAmount ?? .zero) / Decimal(input.daughterCount)
            nodes[id] = FaraidhGraphNode(
                id: id,
                displayName: "Daughter \(i)",
                generationLevel: -1,
                relationType: .daughter,
                status: share != nil ? .active : .mahjubHirman,
                baseShareFraction: share?.fraction.toDisplayString(),
                finalPercentage: daughterPct,
                cashValue: daughterCash,
                visualColorHex: share != nil ? "#10B981" : "#EF4444"
            )
            edges.append(FaraidhGraphEdge(fromId: rootId, toId: id, type: .parentChild))
        }
        
        // 4. Disqualified heirs
        for (idx, dq) in input.disqualifiedHeirs.enumerated() {
            let id = "dq_\(dq.type.rawValue.lowercased())_\(idx)"
            nodes[id] = FaraidhGraphNode(
                id: id,
                displayName: "\(dq.type.rawValue.lowercased().capitalized) (Excluded)",
                generationLevel: (dq.type == .son || dq.type == .daughter) ? -1 : 0,
                relationType: dq.type,
                status: .excludedByLaw,
                disqualificationReasonId: dq.reason.rawValue.lowercased(),
                visualColorHex: "#EF4444"
            )
            edges.append(FaraidhGraphEdge(fromId: rootId, toId: id, type: .parentChild))
        }
        
        return FaraidhFamilyGraph(rootDeceasedId: rootId, nodes: nodes, edges: edges)
    }
}
