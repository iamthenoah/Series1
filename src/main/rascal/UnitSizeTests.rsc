module UnitSizeTests

import lang::java::m3::Core;
import lang::java::m3::AST;
import util::Test;
import UnitSize;
import UnitMetricHelper;
import IO;
import util::Math;
import List;


// Test resource file
private loc fileA = |project://series1/src/test/rascal/resources/TestCode.java|;


// =============================================================
// 1. extractUnits should detect exactly ONE method
// =============================================================
test bool extractUnits_finds_one_method() {
    list[tuple[loc,Declaration]] units = extractUnits([fileA]);
    return size(units) == 1;
}


// =============================================================
// 2. Unit Size for TestCode should be exactly 13
// =============================================================
test bool unitSize_correct_value() {
    UnitMetric us = calculateUnitSize([fileA]);

    return
        us.totalUnits == 1 &&
        us.values == [13] &&
        us.average == 13.0;
}


// =============================================================
// 3. Risk profile: one medium, no others
// =============================================================
test bool unitSize_riskProfile() {
    UnitMetric us = calculateUnitSize([fileA]);

    return
        us.riskProfiles["small"] == 0 &&
        us.riskProfiles["medium"] == 1 &&
        us.riskProfiles["large"] == 0 &&
        us.riskProfiles["veryLarge"] == 0;
}


// =============================================================
// 4. SIG Rating: average=13.0 → threshold <10 → “+”
// =============================================================
test bool unitSize_sigRating() {
    UnitMetric us = calculateUnitSize([fileA]);
    return us.rating == "+";
}


// =============================================================
// 5. Stability test: two calls produce same output
// =============================================================
test bool unitSize_stability() {
    UnitMetric a = calculateUnitSize([fileA]);
    UnitMetric b = calculateUnitSize([fileA]);
    return a == b;
}

