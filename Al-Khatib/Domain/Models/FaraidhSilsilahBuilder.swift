import Foundation

struct FaraidhSilsilahBuilder {
    private static let deceasedId = "deceased"
    
    static func build(
        profile: DeceasedProfile,
        input: HeirInput,
        activeShares: [HeirShare],
        blocked: [BlockedHeir],
        names: FaraidhParticipantNames = FaraidhParticipantNames()
    ) -> [SilsilahNode] {
        var nodes: [SilsilahNode] = []
        let activeTypes = Set(activeShares.map { $0.type })
        let blockedMap = Dictionary(grouping: blocked, by: { $0.type })
        
        let deceasedLabel = profile.name.isEmpty ? "" : profile.name
        nodes.append(SilsilahNode(
            id: deceasedId,
            parentNodeId: nil,
            generationLevel: 0,
            type: .son, // Deceased placeholder
            labelKey: "faraidh_node_deceased",
            headCount: 1,
            inherits: false,
            blocked: false,
            blockReason: nil,
            displayName: deceasedLabel
        ))
        
        if input.fatherCount > 0 {
            let reason = blockedMap[.father]?.first?.reason
            nodes.append(node(
                id: "father", parentId: deceasedId, generation: -1, type: .father, labelKey: "faraidh_heir_father", heads: 1,
                inherits: activeTypes.contains(.father), blocked: reason != nil, blockReason: reason, displayName: names.fatherName, activeShares: activeShares, bornOutOfWedlock: profile.bornOutOfWedlock
            ))
        }
        
        if input.grandfatherCount > 0 {
            let reason = blockedMap[.grandfather]?.first?.reason
            let parentId = input.fatherCount > 0 ? "father" : deceasedId
            nodes.append(node(
                id: "grandfather", parentId: parentId, generation: -2, type: .grandfather, labelKey: "faraidh_heir_grandfather", heads: 1,
                inherits: activeTypes.contains(.grandfather), blocked: reason != nil, blockReason: reason, displayName: names.grandfatherName, activeShares: activeShares, bornOutOfWedlock: profile.bornOutOfWedlock
            ))
        }
        
        if input.motherCount > 0 {
            let reason = blockedMap[.mother]?.first?.reason
            nodes.append(node(
                id: "mother", parentId: deceasedId, generation: -1, type: .mother, labelKey: "faraidh_heir_mother", heads: 1,
                inherits: activeTypes.contains(.mother), blocked: reason != nil, blockReason: reason, displayName: names.motherName, activeShares: activeShares, bornOutOfWedlock: profile.bornOutOfWedlock
            ))
        }
        
        if profile.gender == .male && input.wifeCount > 0 {
            for i in 0..<input.wifeCount {
                let wifeName = names.wifeNames.indices.contains(i) ? names.wifeNames[i] : ""
                let reason = blockedMap[.wife]?.first?.reason
                nodes.append(node(
                    id: "wife_\(i)", parentId: deceasedId, generation: 0, type: .wife, labelKey: "faraidh_heir_wife",
                    heads: 1, inherits: activeTypes.contains(.wife), blocked: reason != nil, blockReason: reason, displayName: wifeName, activeShares: activeShares, bornOutOfWedlock: profile.bornOutOfWedlock
                ))
            }
        }
        
        if profile.gender == .female && input.husbandCount > 0 {
            let reason = blockedMap[.husband]?.first?.reason
            nodes.append(node(
                id: "husband", parentId: deceasedId, generation: 0, type: .husband, labelKey: "faraidh_heir_husband",
                heads: 1, inherits: activeTypes.contains(.husband), blocked: reason != nil, blockReason: reason, displayName: names.husbandName, activeShares: activeShares, bornOutOfWedlock: profile.bornOutOfWedlock
            ))
        }
        
        addChildBranch(&nodes, input: input, activeTypes: activeTypes, blockedMap: blockedMap, names: names, activeShares: activeShares, bornOutOfWedlock: profile.bornOutOfWedlock)
        addSiblingBranch(&nodes, input: input, activeTypes: activeTypes, blockedMap: blockedMap, names: names, activeShares: activeShares, bornOutOfWedlock: profile.bornOutOfWedlock)
        
        return nodes
    }
    
    private static func addChildBranch(
        _ nodes: inout [SilsilahNode],
        input: HeirInput,
        activeTypes: Set<HeirType>,
        blockedMap: [HeirType: [BlockedHeir]],
        names: FaraidhParticipantNames,
        activeShares: [HeirShare],
        bornOutOfWedlock: Bool
    ) {
        if input.sonCount > 0 {
            for i in 0..<input.sonCount {
                let reason = blockedMap[.son]?.first?.reason
                nodes.append(node(
                    id: "son_\(i)", parentId: deceasedId, generation: 1, type: .son, labelKey: "faraidh_heir_son", heads: 1,
                    inherits: activeTypes.contains(.son), blocked: reason != nil, blockReason: reason,
                    displayName: names.sonNames.indices.contains(i) ? names.sonNames[i] : "", activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock
                ))
            }
        }
        
        if input.daughterCount > 0 {
            for i in 0..<input.daughterCount {
                let reason = blockedMap[.daughter]?.first?.reason
                nodes.append(node(
                    id: "daughter_\(i)", parentId: deceasedId, generation: 1, type: .daughter, labelKey: "faraidh_heir_daughter", heads: 1,
                    inherits: activeTypes.contains(.daughter), blocked: reason != nil, blockReason: reason,
                    displayName: names.daughterNames.indices.contains(i) ? names.daughterNames[i] : "", activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock
                ))
            }
        }
        
        if input.grandsonCount > 0 {
            let reason = blockedMap[.grandson]?.first?.reason
            for i in 0..<input.grandsonCount {
                nodes.append(node(
                    id: "grandson_\(i)", parentId: "son_0", generation: 2, type: .grandson, labelKey: "faraidh_heir_grandson", heads: 1,
                    inherits: activeTypes.contains(.grandson), blocked: reason != nil, blockReason: reason,
                    displayName: names.grandsonNames.indices.contains(i) ? names.grandsonNames[i] : "", activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock
                ))
            }
        }
        
        if input.granddaughterCount > 0 {
            let reason = blockedMap[.granddaughter]?.first?.reason
            for i in 0..<input.granddaughterCount {
                nodes.append(node(
                    id: "granddaughter_\(i)", parentId: "son_0", generation: 2, type: .granddaughter, labelKey: "faraidh_heir_granddaughter", heads: 1,
                    inherits: activeTypes.contains(.granddaughter), blocked: reason != nil, blockReason: reason,
                    displayName: names.granddaughterNames.indices.contains(i) ? names.granddaughterNames[i] : "", activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock
                ))
            }
        }
    }
    
    private static func addSiblingBranch(
        _ nodes: inout [SilsilahNode],
        input: HeirInput,
        activeTypes: Set<HeirType>,
        blockedMap: [HeirType: [BlockedHeir]],
        names: FaraidhParticipantNames,
        activeShares: [HeirShare],
        bornOutOfWedlock: Bool
    ) {
        addIndividualSiblings(&nodes, count: input.fullBrotherCount, nameList: names.fullBrotherNames, idPrefix: "full_bro", type: .fullBrother, activeTypes: activeTypes, blockedMap: blockedMap, activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock)
        addIndividualSiblings(&nodes, count: input.fullSisterCount, nameList: names.fullSisterNames, idPrefix: "full_sis", type: .fullSister, activeTypes: activeTypes, blockedMap: blockedMap, activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock)
        addIndividualSiblings(&nodes, count: input.paternalBrotherCount, nameList: names.paternalBrotherNames, idPrefix: "paternal_bro", type: .paternalBrother, activeTypes: activeTypes, blockedMap: blockedMap, activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock)
        addIndividualSiblings(&nodes, count: input.paternalSisterCount, nameList: names.paternalSisterNames, idPrefix: "paternal_sis", type: .paternalSister, activeTypes: activeTypes, blockedMap: blockedMap, activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock)
        
        for i in 0..<input.maternalBrotherCount {
            let reason = blockedMap[.maternalSibling]?.first?.reason
            nodes.append(node(
                id: "maternal_bro_\(i)", parentId: deceasedId, generation: 0, type: .maternalSibling, labelKey: "faraidh_heir_maternal_sibling", heads: 1,
                inherits: activeTypes.contains(.maternalSibling), blocked: reason != nil, blockReason: reason,
                displayName: names.maternalBrotherNames.indices.contains(i) ? names.maternalBrotherNames[i] : "", activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock
            ))
        }
        
        for i in 0..<input.maternalSisterCount {
            let reason = blockedMap[.maternalSibling]?.first?.reason
            nodes.append(node(
                id: "maternal_sis_\(i)", parentId: deceasedId, generation: 0, type: .maternalSibling, labelKey: "faraidh_heir_maternal_sibling", heads: 1,
                inherits: activeTypes.contains(.maternalSibling), blocked: reason != nil, blockReason: reason,
                displayName: names.maternalSisterNames.indices.contains(i) ? names.maternalSisterNames[i] : "", activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock
            ))
        }
    }
    
    private static func addIndividualSiblings(
        _ nodes: inout [SilsilahNode],
        count: Int,
        nameList: [String],
        idPrefix: String,
        type: HeirType,
        activeTypes: Set<HeirType>,
        blockedMap: [HeirType: [BlockedHeir]],
        activeShares: [HeirShare],
        bornOutOfWedlock: Bool
    ) {
        if count <= 0 { return }
        let reason = blockedMap[type]?.first?.reason
        for i in 0..<count {
            nodes.append(node(
                id: "\(idPrefix)_\(i)", parentId: deceasedId, generation: 0, type: type, labelKey: heirLabelKey(type), heads: 1,
                inherits: activeTypes.contains(type), blocked: reason != nil, blockReason: reason,
                displayName: nameList.indices.contains(i) ? nameList[i] : "", activeShares: activeShares, bornOutOfWedlock: bornOutOfWedlock
            ))
        }
    }
    
    private static func heirLabelKey(_ type: HeirType) -> String {
        switch type {
        case .husband: return "faraidh_heir_husband"
        case .wife: return "faraidh_heir_wife"
        case .father: return "faraidh_heir_father"
        case .grandfather: return "faraidh_heir_grandfather"
        case .mother: return "faraidh_heir_mother"
        case .son: return "faraidh_heir_son"
        case .daughter: return "faraidh_heir_daughter"
        case .grandson: return "faraidh_heir_grandson"
        case .granddaughter: return "faraidh_heir_granddaughter"
        case .fullBrother: return "faraidh_heir_full_brother"
        case .fullSister: return "faraidh_heir_full_sister"
        case .paternalBrother: return "faraidh_heir_paternal_brother"
        case .paternalSister: return "faraidh_heir_paternal_sister"
        case .maternalSibling: return "faraidh_heir_maternal_sibling"
        case .stepChild: return "faraidh_heir_step_child"
        case .unbornFetus: return "faraidh_heir_unborn_fetus"
        }
    }
    
    private static func node(
        id: String,
        parentId: String,
        generation: Int,
        type: HeirType,
        labelKey: String,
        heads: Int,
        inherits: Bool,
        blocked: Bool,
        blockReason: BlockingReasonKey?,
        displayName: String = "",
        activeShares: [HeirShare] = [],
        bornOutOfWedlock: Bool = false
    ) -> SilsilahNode {
        let actualType = (bornOutOfWedlock && (type == .fullBrother || type == .fullSister)) ? HeirType.maternalSibling : type
        let matchingShare = activeShares.first { $0.type == actualType }
        let actualInherits = (bornOutOfWedlock && (type == .fullBrother || type == .fullSister)) ?
            activeShares.contains { $0.type == .maternalSibling } : inherits
            
        var frac: String? = nil
        var pct: String? = nil
        var amt: Decimal? = nil
        
        if let share = matchingShare, actualInherits {
            let indivFrac = share.fraction.divideAmongHeads(share.headCount)
            let indivPercent = share.percentage / Decimal(share.headCount)
            let indivAmount = share.cashAmount / Decimal(share.headCount)
            frac = indivFrac.toDisplayString()
            pct = "\(indivPercent)%"
            amt = indivAmount
        }
        
        return SilsilahNode(
            id: id,
            parentNodeId: parentId,
            generationLevel: generation,
            type: type,
            labelKey: labelKey,
            headCount: heads,
            inherits: actualInherits,
            blocked: blocked,
            blockReason: blockReason,
            displayName: displayName,
            shareFraction: frac,
            sharePercentage: pct,
            shareAmount: amt
        )
    }
}
