import Foundation

class FaraidhEngine {
    
    private struct Slot {
        let type: HeirType
        let heads: Int
        var fraction: FaraidhFraction
        let isAsabah: Bool
        var proofKeys: [String] = []
    }
    
    static func calculate(
        profile: DeceasedProfile,
        input: HeirInput,
        names: FaraidhParticipantNames = FaraidhParticipantNames(),
        madhhab: FaraidhMadhhab = .shafii
    ) -> FaraidhResult {
        let estate = max(.zero, profile.netEstate)
        var blocked: [BlockedHeir] = []
        
        for dq in input.disqualifiedHeirs {
            blocked.append(BlockedHeir(type: dq.type, headCount: dq.count, reason: dq.reason))
        }
        
        if !input.hasAnyHeir() {
            let fallback = DzawilArhamResolver.resolve(estate: estate, input: input)
            let graph = FaraidhGraphBuilder.build(profile: profile, input: input, activeShares: fallback.activeShares, blockedHeirs: blocked)
            return FaraidhResult(
                deceased: profile,
                input: input,
                activeShares: fallback.activeShares,
                blockedHeirs: blocked,
                silsilah: [],
                adjustment: .none,
                adjustmentNoteKey: fallback.noteKey,
                proofKeys: fallback.proofKeys,
                totalDistributed: estate,
                remainderFraction: .zero,
                madhhab: madhhab,
                madhhabNoteKey: madhhabNoteKey(madhhab),
                familyGraph: graph
            )
        }
        
        let ctx = analyze(input: input, gender: profile.gender, bornOutOfWedlock: profile.bornOutOfWedlock)
        
        var mutableBlocked = blocked
        resolveBlocking(input: input, ctx: ctx, blocked: &mutableBlocked, bornOutOfWedlock: profile.bornOutOfWedlock)
        blocked = mutableBlocked
        
        var slots: [Slot] = []
        
        // Akdariyah check
        let isAkdariyah = ctx.hasGrandfather
            && !ctx.hasFather && !ctx.hasChild && !ctx.hasGrandchild
            && input.motherCount > 0
            && (input.husbandCount > 0 || input.wifeCount > 0)
            && (input.fullSisterCount > 0)
            && input.fullBrotherCount == 0
            && input.paternalBrotherCount == 0 && input.paternalSisterCount == 0
            
        if isAkdariyah {
            return calculateAkdariyah(profile: profile, input: input, ctx: ctx, blocked: blocked, slots: &slots, estate: estate, madhhab: madhhab, names: names)
        }
        
        assignFixedShares(input: input, profile: profile, ctx: ctx, slots: &slots, blocked: &mutableBlocked, madhhab: madhhab)
        blocked = mutableBlocked
        
        assignAsabahResidue(input: input, ctx: ctx, slots: &slots, blocked: &mutableBlocked, madhhab: madhhab)
        blocked = mutableBlocked
        
        var adjustment: FaraidhAdjustment = .none
        var adjustmentNoteKey: String? = nil
        
        let fixedTotal = FaraidhFraction.sumOf(slots.map { $0.fraction })
        if fixedTotal.numerator > fixedTotal.denominator {
            adjustment = .awl
            adjustmentNoteKey = "faraidh_awl_note"
            let scaled = FaraidhFraction.applyAwl(shares: slots.map { ($0.type, $0.fraction) })
            for idx in 0..<slots.count {
                slots[idx].fraction = scaled[idx].1
            }
        } else if fixedTotal.numerator < fixedTotal.denominator && !slots.contains(where: { $0.isAsabah && $0.fraction.numerator > 0 }) {
            adjustment = .radd
            adjustmentNoteKey = madhhab.raddIncludesSpouses() ? "faraidh_radd_note_hanafi" : "faraidh_radd_note"
            let spouseTypes: Set<HeirType> = madhhab.raddIncludesSpouses() ? [] : [.husband, .wife]
            let radd = FaraidhFraction.applyRadd(shares: slots.map { ($0.type, $0.fraction, $0.isAsabah) }, spouseTypes: spouseTypes)
            for idx in 0..<slots.count {
                slots[idx].fraction = radd[idx].1
            }
        }
        
        let activeShares = slots
            .filter { $0.heads > 0 && $0.fraction.numerator > 0 }
            .map { slot -> HeirShare in
                HeirShare(
                    type: slot.type,
                    headCount: slot.heads,
                    fraction: slot.fraction,
                    percentage: slot.fraction.toPercentage(scale: 1),
                    cashAmount: slot.fraction.toCashAmount(estate: estate),
                    isAsabah: slot.isAsabah,
                    proofKeys: Array(Set(slot.proofKeys)).sorted()
                )
            }
            
        let silsilah = FaraidhSilsilahBuilder.build(profile: profile, input: input, activeShares: activeShares, blocked: blocked, names: names)
        
        let extraProofKeys = profile.bornOutOfWedlock ? ["proof_out_of_wedlock", "proof_out_of_wedlock_note"] : []
        var proofKeys = Array(Set(activeShares.flatMap { $0.proofKeys })).sorted()
        if adjustmentNoteKey != nil {
            proofKeys.append("proof_awl_radd")
        }
        proofKeys.append(contentsOf: extraProofKeys)
        proofKeys = Array(Set(proofKeys)).sorted()
        
        let totalDistributed = activeShares.reduce(.zero) { $0 + $1.cashAmount }
        let remainderUsed = FaraidhFraction.sumOf(activeShares.map { $0.fraction })
        let remainder = FaraidhFraction(numerator: remainderUsed.denominator - remainderUsed.numerator, denominator: remainderUsed.denominator).normalized()
        
        var finalShares = activeShares
        var finalAdjustmentNoteKey = adjustmentNoteKey
        var finalProofKeys = proofKeys
        var finalTotalDistributed = totalDistributed
        var finalRemainder = remainder
        
        if finalShares.isEmpty {
            let fallback = DzawilArhamResolver.resolve(estate: estate, input: input)
            finalShares = fallback.activeShares
            finalAdjustmentNoteKey = fallback.noteKey
            finalProofKeys = Array(Set(finalProofKeys + fallback.proofKeys)).sorted()
            finalTotalDistributed = estate
            finalRemainder = .zero
        }
        
        let graph = FaraidhGraphBuilder.build(profile: profile, input: input, activeShares: finalShares, blockedHeirs: blocked)
        let classicalCase = detectClassicalCase(input: input, ctx: ctx, madhhab: madhhab)
        
        return FaraidhResult(
            deceased: profile,
            input: input,
            activeShares: finalShares,
            blockedHeirs: blocked,
            silsilah: silsilah,
            adjustment: adjustment,
            adjustmentNoteKey: finalAdjustmentNoteKey,
            proofKeys: finalProofKeys,
            totalDistributed: finalTotalDistributed,
            remainderFraction: finalRemainder,
            madhhab: madhhab,
            madhhabNoteKey: madhhabNoteKey(madhhab),
            familyGraph: graph,
            classicalCase: classicalCase
        )
    }
    
    private static func calculateAkdariyah(
        profile: DeceasedProfile,
        input: HeirInput,
        ctx: Context,
        blocked: [BlockedHeir],
        slots: inout [Slot],
        estate: Decimal,
        madhhab: FaraidhMadhhab,
        names: FaraidhParticipantNames
    ) -> FaraidhResult {
        if input.husbandCount > 0 {
            slots.append(Slot(type: .husband, heads: 1, fraction: FaraidhFraction.of(numerator: 1, denominator: 2), isAsabah: false, proofKeys: ["proof_husband_half"]))
        }
        if input.wifeCount > 0 {
            slots.append(Slot(type: .wife, heads: input.wifeCount, fraction: FaraidhFraction.of(numerator: 1, denominator: 4), isAsabah: false, proofKeys: ["proof_wife_quarter"]))
        }
        slots.append(Slot(type: .mother, heads: 1, fraction: FaraidhFraction.of(numerator: 1, denominator: 3), isAsabah: false, proofKeys: ["proof_mother_third"]))
        slots.append(Slot(type: .grandfather, heads: 1, fraction: FaraidhFraction.of(numerator: 1, denominator: 6), isAsabah: false, proofKeys: ["proof_grandfather_sixth", "proof_akdariyah"]))
        slots.append(Slot(type: .fullSister, heads: input.fullSisterCount, fraction: FaraidhFraction.of(numerator: 1, denominator: 6), isAsabah: false, proofKeys: ["proof_sisters_fixed", "proof_akdariyah"]))
        
        let rawTotal = FaraidhFraction.sumOf(slots.map { $0.fraction })
        var adjustment: FaraidhAdjustment = .none
        if rawTotal.numerator > rawTotal.denominator {
            adjustment = .awl
            let scaled = FaraidhFraction.applyAwl(shares: slots.map { ($0.type, $0.fraction) })
            for idx in 0..<slots.count {
                slots[idx].fraction = scaled[idx].1
            }
        }
        
        let gfIdx = slots.firstIndex(where: { $0.type == .grandfather })
        let sisIdx = slots.firstIndex(where: { $0.type == .fullSister })
        if let gf = gfIdx, let sis = sisIdx {
            let combined = slots[gf].fraction.add(slots[sis].fraction).normalized()
            let grandfatherShare = FaraidhFraction(numerator: combined.numerator * 2, denominator: combined.denominator * 3).normalized()
            let sisterShare = FaraidhFraction(numerator: combined.numerator, denominator: combined.denominator * 3).normalized()
            slots[gf].fraction = grandfatherShare
            slots[sis].fraction = sisterShare
        }
        
        let activeShares = slots
            .filter { $0.heads > 0 && $0.fraction.numerator > 0 }
            .map { slot -> HeirShare in
                HeirShare(
                    type: slot.type,
                    headCount: slot.heads,
                    fraction: slot.fraction,
                    percentage: slot.fraction.toPercentage(scale: 1),
                    cashAmount: slot.fraction.toCashAmount(estate: estate),
                    isAsabah: slot.isAsabah,
                    proofKeys: Array(Set(slot.proofKeys)).sorted()
                )
            }
            
        let silsilah = FaraidhSilsilahBuilder.build(profile: profile, input: input, activeShares: activeShares, blocked: blocked, names: names)
        let graph = FaraidhGraphBuilder.build(profile: profile, input: input, activeShares: activeShares, blockedHeirs: blocked)
        let totalDistributed = activeShares.reduce(.zero) { $0 + $1.cashAmount }
        
        return FaraidhResult(
            deceased: profile,
            input: input,
            activeShares: activeShares,
            blockedHeirs: blocked,
            silsilah: silsilah,
            adjustment: adjustment,
            adjustmentNoteKey: adjustment == .awl ? "faraidh_awl_note" : nil,
            proofKeys: ["proof_akdariyah"],
            totalDistributed: totalDistributed,
            remainderFraction: .zero,
            madhhab: madhhab,
            madhhabNoteKey: madhhabNoteKey(madhhab),
            familyGraph: graph,
            classicalCase: .alAkdariyah
        )
    }
    
    private static func madhhabNoteKey(_ madhhab: FaraidhMadhhab) -> String {
        switch madhhab {
        case .hanafi: return "madhhab_hanafi"
        case .maliki: return "madhhab_maliki"
        case .shafii: return "madhhab_shafii"
        case .hanbali: return "madhhab_hanbali"
        }
    }
    
    private struct Context {
        let hasSon: Bool
        let hasDaughter: Bool
        let hasChild: Bool
        let hasGrandson: Bool
        let hasGranddaughter: Bool
        let hasGrandchild: Bool
        let hasFather: Bool
        let hasGrandfather: Bool
        let grandfatherBlocksSiblings: Bool
        let hasMother: Bool
        let siblingHeads: Int
        let hasTwoOrMoreSiblings: Bool
        let siblingsBlocked: Bool
        let grandchildrenBlocked: Bool
        let bornOutOfWedlock: Bool
    }
    
    private static func analyze(input: HeirInput, gender: DeceasedGender, bornOutOfWedlock: Bool) -> Context {
        let hasSon = input.sonCount > 0
        let hasDaughter = input.daughterCount > 0
        let hasChild = hasSon || hasDaughter
        let grandchildrenBlocked = hasChild
        let hasGrandson = input.grandsonCount > 0 && !grandchildrenBlocked
        let hasGranddaughter = input.granddaughterCount > 0 && !grandchildrenBlocked
        
        let effectiveFatherCount = bornOutOfWedlock ? 0 : input.fatherCount
        let hasFather = effectiveFatherCount > 0
        let hasGrandfather = !hasFather && input.grandfatherCount > 0
        
        let siblingHeads = bornOutOfWedlock ?
            (input.maternalBrotherCount + input.maternalSisterCount + input.fullBrotherCount + input.fullSisterCount) :
            (input.fullBrotherCount + input.fullSisterCount +
             input.paternalBrotherCount + input.paternalSisterCount +
             input.maternalBrotherCount + input.maternalSisterCount)
             
        let grandfatherBlocksSiblings = hasGrandfather && !hasChild && !hasGrandson && !hasGranddaughter
        let siblingsBlocked = hasChild || hasFather
        
        return Context(
            hasSon: hasSon,
            hasDaughter: hasDaughter,
            hasChild: hasChild,
            hasGrandson: hasGrandson,
            hasGranddaughter: hasGranddaughter,
            hasGrandchild: hasGrandson || hasGranddaughter,
            hasFather: hasFather,
            hasGrandfather: hasGrandfather,
            grandfatherBlocksSiblings: grandfatherBlocksSiblings,
            hasMother: input.motherCount > 0,
            siblingHeads: siblingHeads,
            hasTwoOrMoreSiblings: siblingHeads >= 2,
            siblingsBlocked: siblingsBlocked,
            grandchildrenBlocked: grandchildrenBlocked,
            bornOutOfWedlock: bornOutOfWedlock
        )
    }
    
    private static func resolveBlocking(
        input: HeirInput,
        ctx: Context,
        blocked: inout [BlockedHeir],
        bornOutOfWedlock: Bool
    ) {
        if bornOutOfWedlock {
            if input.fatherCount > 0 { blocked.append(BlockedHeir(type: .father, headCount: input.fatherCount, reason: .outOfWedlock)) }
            if input.paternalBrotherCount > 0 { blocked.append(BlockedHeir(type: .paternalBrother, headCount: input.paternalBrotherCount, reason: .outOfWedlock)) }
            if input.paternalSisterCount > 0 { blocked.append(BlockedHeir(type: .paternalSister, headCount: input.paternalSisterCount, reason: .outOfWedlock)) }
        }
        
        if ctx.grandchildrenBlocked {
            addBlocked(count: input.grandsonCount, type: .grandson, reason: .byChildren, blocked: &blocked)
            addBlocked(count: input.granddaughterCount, type: .granddaughter, reason: .byChildren, blocked: &blocked)
        }
        if ctx.siblingsBlocked {
            let reason = ctx.hasChild ? BlockingReasonKey.byChildren : BlockingReasonKey.byFather
            if !bornOutOfWedlock {
                addBlocked(count: input.fullBrotherCount, type: .fullBrother, reason: reason, blocked: &blocked)
                addBlocked(count: input.fullSisterCount, type: .fullSister, reason: reason, blocked: &blocked)
                addBlocked(count: input.paternalBrotherCount, type: .paternalBrother, reason: reason, blocked: &blocked)
                addBlocked(count: input.paternalSisterCount, type: .paternalSister, reason: reason, blocked: &blocked)
            } else {
                if ctx.hasChild {
                    addBlocked(count: input.fullBrotherCount, type: .fullBrother, reason: reason, blocked: &blocked)
                    addBlocked(count: input.fullSisterCount, type: .fullSister, reason: reason, blocked: &blocked)
                }
            }
            let maternalHeads = input.maternalBrotherCount + input.maternalSisterCount
            if maternalHeads > 0 { blocked.append(BlockedHeir(type: .maternalSibling, headCount: maternalHeads, reason: reason)) }
        }
        
        if ctx.grandfatherBlocksSiblings && !bornOutOfWedlock {
            addBlocked(count: input.fullBrotherCount, type: .fullBrother, reason: .byGrandfather, blocked: &blocked)
            addBlocked(count: input.fullSisterCount, type: .fullSister, reason: .byGrandfather, blocked: &blocked)
            addBlocked(count: input.paternalBrotherCount, type: .paternalBrother, reason: .byGrandfather, blocked: &blocked)
            addBlocked(count: input.paternalSisterCount, type: .paternalSister, reason: .byGrandfather, blocked: &blocked)
        }
    }
    
    private static func addBlocked(count: Int, type: HeirType, reason: BlockingReasonKey, blocked: inout [BlockedHeir]) {
        if count > 0 {
            blocked.append(BlockedHeir(type: type, headCount: count, reason: reason))
        }
    }
    
    private static func assignFixedShares(
        input: HeirInput,
        profile: DeceasedProfile,
        ctx: Context,
        slots: inout [Slot],
        blocked: inout [BlockedHeir],
        madhhab: FaraidhMadhhab
    ) {
        switch profile.gender {
        case .female:
            if input.husbandCount > 0 {
                let base = ctx.hasChild ? FaraidhFraction.of(numerator: 1, denominator: 4) : FaraidhFraction.of(numerator: 1, denominator: 2)
                let perHead = base.divideAmongHeads(input.husbandCount)
                slots.append(Slot(type: .husband, heads: input.husbandCount, fraction: perHead.multiplyScalar(input.husbandCount), isAsabah: false,
                                  proofKeys: [ctx.hasChild ? "proof_husband_quarter" : "proof_husband_half"]))
            }
            if input.wifeCount > 0 { addBlocked(count: input.wifeCount, type: .wife, reason: .genderMismatch, blocked: &blocked) }
        case .male:
            if input.wifeCount > 0 {
                let base = ctx.hasChild ? FaraidhFraction.of(numerator: 1, denominator: 8) : FaraidhFraction.of(numerator: 1, denominator: 4)
                slots.append(Slot(type: .wife, heads: input.wifeCount, fraction: base, isAsabah: false,
                                  proofKeys: [ctx.hasChild ? "proof_wife_eighth" : "proof_wife_quarter"]))
            }
            if input.husbandCount > 0 { addBlocked(count: input.husbandCount, type: .husband, reason: .genderMismatch, blocked: &blocked) }
        }
        
        // Father
        if ctx.hasFather {
            if ctx.hasChild || ctx.hasGrandchild {
                slots.append(Slot(type: .father, heads: 1, fraction: FaraidhFraction.of(numerator: 1, denominator: 6), isAsabah: false, proofKeys: ["proof_father_sixth"]))
            }
        }
        
        // Grandfather
        if ctx.hasGrandfather {
            if ctx.hasChild || ctx.hasGrandchild {
                slots.append(Slot(type: .grandfather, heads: 1, fraction: FaraidhFraction.of(numerator: 1, denominator: 6), isAsabah: false, proofKeys: ["proof_grandfather_sixth"]))
            }
        }
        
        // Mother
        if ctx.hasMother {
            let share = (ctx.hasChild || ctx.hasTwoOrMoreSiblings) ? FaraidhFraction.of(numerator: 1, denominator: 6) : FaraidhFraction.of(numerator: 1, denominator: 3)
            slots.append(Slot(type: .mother, heads: 1, fraction: share, isAsabah: false,
                              proofKeys: [(ctx.hasChild || ctx.hasTwoOrMoreSiblings) ? "proof_mother_sixth" : "proof_mother_third"]))
        }
        
        // Daughters (furud only when no son)
        if ctx.hasDaughter && !ctx.hasSon {
            let share = input.daughterCount == 1 ? FaraidhFraction.of(numerator: 1, denominator: 2) : FaraidhFraction.of(numerator: 2, denominator: 3)
            slots.append(Slot(type: .daughter, heads: input.daughterCount, fraction: share, isAsabah: false,
                              proofKeys: [input.daughterCount == 1 ? "proof_daughter_half" : "proof_daughters_two_thirds"]))
        }
        
        // Siblings
        if !ctx.siblingsBlocked {
            let maternalHeads = profile.bornOutOfWedlock ?
                (input.maternalBrotherCount + input.maternalSisterCount + input.fullBrotherCount + input.fullSisterCount) :
                (input.maternalBrotherCount + input.maternalSisterCount)
                
            if maternalHeads > 0 {
                let share = maternalHeads == 1 ? FaraidhFraction.of(numerator: 1, denominator: 6) : FaraidhFraction.of(numerator: 1, denominator: 3)
                slots.append(Slot(type: .maternalSibling, heads: maternalHeads, fraction: share, isAsabah: false, proofKeys: ["proof_maternal_siblings"]))
            }
            
            if !profile.bornOutOfWedlock && input.fullBrotherCount == 0 && input.fullSisterCount > 0 && !ctx.hasChild && !ctx.grandfatherBlocksSiblings {
                let share = input.fullSisterCount == 1 ? FaraidhFraction.of(numerator: 1, denominator: 2) : FaraidhFraction.of(numerator: 2, denominator: 3)
                slots.append(Slot(type: .fullSister, heads: input.fullSisterCount, fraction: share, isAsabah: false, proofKeys: ["proof_sisters_fixed"]))
            }
            
            // Al-Marwaniyah (Maliki)
            let isMarwaniyah = !profile.bornOutOfWedlock
                && (input.husbandCount > 0 || input.wifeCount > 0)
                && input.motherCount > 0
                && (input.fullBrotherCount > 0)
                && (input.maternalBrotherCount + input.maternalSisterCount) > 0
                && !ctx.hasChild && !ctx.hasFather && !ctx.hasGrandfather
                
            if isMarwaniyah && madhhab == .maliki {
                if let mIdx = slots.firstIndex(where: { $0.type == .maternalSibling }) {
                    let totalSiblings = (input.maternalBrotherCount + input.maternalSisterCount) + input.fullBrotherCount +
                        (input.fullSisterCount > 0 && input.fullBrotherCount == 0 ? 0 : input.fullSisterCount)
                    let share = totalSiblings == 1 ? FaraidhFraction.of(numerator: 1, denominator: 6) : FaraidhFraction.of(numerator: 1, denominator: 3)
                    
                    let maternalCombinedHeads = input.maternalBrotherCount + input.maternalSisterCount
                    slots[mIdx] = Slot(
                        type: .maternalSibling,
                        heads: maternalCombinedHeads,
                        fraction: share.multiply(FaraidhFraction.of(numerator: Int(maternalCombinedHeads), denominator: Int(totalSiblings))).normalized(),
                        isAsabah: false,
                        proofKeys: ["proof_marwaniyah"]
                    )
                    
                    slots.append(Slot(
                        type: .fullBrother,
                        heads: input.fullBrotherCount,
                        fraction: share.multiply(FaraidhFraction.of(numerator: Int(input.fullBrotherCount), denominator: Int(totalSiblings))).normalized(),
                        isAsabah: false,
                        proofKeys: ["proof_marwaniyah"]
                    ))
                }
            }
            
            if !profile.bornOutOfWedlock && input.paternalBrotherCount == 0 && input.paternalSisterCount > 0
                && input.fullBrotherCount == 0 && input.fullSisterCount == 0 && !ctx.hasChild && !ctx.grandfatherBlocksSiblings {
                let share = input.paternalSisterCount == 1 ? FaraidhFraction.of(numerator: 1, denominator: 2) : FaraidhFraction.of(numerator: 2, denominator: 3)
                slots.append(Slot(type: .paternalSister, heads: input.paternalSisterCount, fraction: share, isAsabah: false, proofKeys: ["proof_sisters_fixed"]))
            }
        }
    }
    
    private static func assignAsabahResidue(
        input: HeirInput,
        ctx: Context,
        slots: inout [Slot],
        blocked: inout [BlockedHeir],
        madhhab: FaraidhMadhhab
    ) {
        let used = FaraidhFraction.sumOf(slots.map { $0.fraction })
        var residue = used.numerator >= used.denominator ?
            FaraidhFraction.zero :
            FaraidhFraction(numerator: used.denominator - used.numerator, denominator: used.denominator).normalized()
            
        if residue.numerator == 0 { return }
        
        let asabahGroups = buildAsabahPriority(input: input, ctx: ctx)
        for group in asabahGroups {
            if residue.numerator == 0 { break }
            let (type, maleHeads, femaleHeads) = (group.type, group.maleHeads, group.femaleHeads)
            if maleHeads + femaleHeads <= 0 { continue }
            
            let maleWeight = maleHeads * 2
            let femaleWeight = femaleHeads
            let totalWeight = maleWeight + femaleWeight
            let groupShare = residue
            
            if maleHeads > 0 {
                let maleFrac = FaraidhFraction(
                    numerator: groupShare.numerator * maleWeight,
                    denominator: groupShare.denominator * totalWeight
                ).divideAmongHeads(maleHeads)
                mergeOrAdd(slots: &slots, incoming: Slot(type: type, heads: maleHeads, fraction: maleFrac.multiplyScalar(maleHeads), isAsabah: true, proofKeys: ["proof_asabah"]))
            }
            
            if femaleHeads > 0 {
                let femaleType = sisterTypeFor(type)
                let femaleFrac = FaraidhFraction(
                    numerator: groupShare.numerator * femaleWeight,
                    denominator: groupShare.denominator * totalWeight
                ).divideAmongHeads(femaleHeads)
                mergeOrAdd(slots: &slots, incoming: Slot(type: femaleType, heads: femaleHeads, fraction: femaleFrac.multiplyScalar(femaleHeads), isAsabah: true, proofKeys: ["proof_asabah"]))
            }
            residue = .zero
            return
        }
        
        let onlyFemaleDescendants = (ctx.hasDaughter && !ctx.hasSon) || (ctx.hasGranddaughter && !ctx.hasGrandson)
        if ctx.hasFather && (!ctx.hasChild && !ctx.hasGrandchild || onlyFemaleDescendants) {
            mergeOrAdd(slots: &slots, incoming: Slot(type: .father, heads: 1, fraction: residue, isAsabah: true, proofKeys: ["proof_father_residue"]))
            return
        }
        
        if ctx.hasGrandfather && (!ctx.hasChild && !ctx.hasGrandchild || onlyFemaleDescendants) {
            mergeOrAdd(slots: &slots, incoming: Slot(type: .grandfather, heads: 1, fraction: residue, isAsabah: true, proofKeys: ["proof_grandfather_residue"]))
        }
    }
    
    private struct AsabahGroup {
        let type: HeirType
        let maleHeads: Int
        let femaleHeads: Int
    }
    
    private static func buildAsabahPriority(input: HeirInput, ctx: Context) -> [AsabahGroup] {
        var list: [AsabahGroup] = []
        if ctx.hasSon {
            list.append(AsabahGroup(type: .son, maleHeads: input.sonCount, femaleHeads: input.daughterCount))
        } else if ctx.hasGrandson {
            list.append(AsabahGroup(type: .grandson, maleHeads: input.grandsonCount, femaleHeads: input.granddaughterCount))
        } else if !ctx.siblingsBlocked && !ctx.grandfatherBlocksSiblings && !ctx.bornOutOfWedlock {
            if input.fullBrotherCount > 0 || input.fullSisterCount > 0 {
                list.append(AsabahGroup(type: .fullBrother, maleHeads: input.fullBrotherCount, femaleHeads: input.fullSisterCount))
            } else if input.paternalBrotherCount > 0 || input.paternalSisterCount > 0 {
                list.append(AsabahGroup(type: .paternalBrother, maleHeads: input.paternalBrotherCount, femaleHeads: input.paternalSisterCount))
            }
        }
        return list
    }
    
    private static func sisterTypeFor(_ brotherType: HeirType) -> HeirType {
        switch brotherType {
        case .son: return .daughter
        case .grandson: return .granddaughter
        case .fullBrother: return .fullSister
        case .paternalBrother: return .paternalSister
        default: return brotherType
        }
    }
    
    private static func mergeOrAdd(slots: inout [Slot], incoming: Slot) {
        if let idx = slots.firstIndex(where: { $0.type == incoming.type && $0.isAsabah == incoming.isAsabah }) {
            let existing = slots[idx]
            slots[idx] = Slot(
                type: existing.type,
                heads: existing.heads,
                fraction: existing.fraction.add(incoming.fraction).normalized(),
                isAsabah: existing.isAsabah,
                proofKeys: Array(Set(existing.proofKeys + incoming.proofKeys)).sorted()
            )
        } else {
            slots.append(incoming)
        }
    }
    
    private static func detectClassicalCase(input: HeirInput, ctx: Context, madhhab: FaraidhMadhhab) -> ClassicalCase? {
        if input.husbandCount == 0 && input.wifeCount > 0 { return nil }
        
        let isMinbariyah = input.husbandCount > 0 &&
            input.motherCount == 1 && input.daughterCount >= 2 &&
            input.fatherCount == 1 && input.sonCount == 0 &&
            input.fullBrotherCount == 0 && input.fullSisterCount == 0 &&
            input.grandfatherCount == 0 && input.maternalBrotherCount == 0 &&
            input.maternalSisterCount == 0
            
        if isMinbariyah { return .alMinbariyah }
        
        let isAkdariyah = ctx.hasGrandfather && !ctx.hasFather && !ctx.hasChild && !ctx.hasGrandchild
            && input.motherCount > 0 && (input.husbandCount > 0 || input.wifeCount > 0)
            && input.fullSisterCount > 0 && input.fullBrotherCount == 0
            
        if isAkdariyah { return .alAkdariyah }
        
        let maternalHeads = input.maternalBrotherCount + input.maternalSisterCount
        let isMarwaniyah = (input.husbandCount > 0 || input.wifeCount > 0)
            && input.motherCount > 0 && input.fullBrotherCount > 0 && maternalHeads > 0
            && !ctx.hasChild && !ctx.hasFather && !ctx.hasGrandfather
            
        if isMarwaniyah { return .alMarwaniyah }
        
        let isUmariyatain = (input.husbandCount > 0 || input.wifeCount > 0)
            && input.fatherCount > 0 && input.motherCount > 0
            && !ctx.hasChild && !ctx.hasGrandchild
            
        if isUmariyatain { return .umariyatain }
        
        return nil
    }
}
