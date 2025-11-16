module UnitComplexityTests

import lang::java::m3::Core;
import lang::java::m3::AST;
import util::Test;
import UnitComplexity;
import UnitMetricHelper;
import List;


// Resource file under test
private loc fileA = |project://series1/src/test/rascal/resources/TestCode.java|;


// =============================================================
// 1. extractUnits must find exactly ONE method
// =============================================================
test bool extractUnits_finds_one_method() {
    list[tuple[loc,Declaration]] units = extractUnits([fileA]);
    return size(units) == 1;
}


// =============================================================
// 2. Complexity must be exactly 4 (1 base + 3 constructs)
// =============================================================
test bool complexity_correct_value() {
    UnitMetric uc = calculateUnitComplexity([fileA]);
    return
        uc.totalUnits == 1 &&
        uc.values == [4] &&
        uc.average == 4.0;
}


// =============================================================
// 3. Risk profile: CC=4 is "low"
// =============================================================
test bool complexity_riskProfile() {
    UnitMetric uc = calculateUnitComplexity([fileA]);

    return
        uc.riskProfiles["low"] == 1 &&
        uc.riskProfiles["moderate"] == 0 &&
        uc.riskProfiles["high"] == 0 &&
        uc.riskProfiles["veryHigh"] == 0;
}


// =============================================================
// 4. SIG Rating: 4 <= 10 → "++"
// =============================================================
test bool complexity_sigRating() {
    UnitMetric uc = calculateUnitComplexity([fileA]);
    return uc.rating == "++";
}


// =============================================================
// 5. Stability test: Multiple runs must produce identical metric
// =============================================================
test bool complexity_stability() {
    UnitMetric a = calculateUnitComplexity([fileA]);
    UnitMetric b = calculateUnitComplexity([fileA]);
    return a == b;
}
