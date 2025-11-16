module UnitSize

import UnitMetricHelper;

import lang::java::m3::AST;
import lang::java::m3::Core;

import List;
import Set;
import util::Math;

// ----------------------------------------------------
// Unit Size thresholds (statements)
// ----------------------------------------------------
public map[str, tuple[int min, int max]] unitSizeThresholds = (
    "small"     : <0, 10>,
    "medium"    : <11, 30>,
    "large"     : <31, 60>,
    "veryLarge" : <61, 999999>
);

// ----------------------------------------------------
// SIG Rating scale for Unit Size
// ----------------------------------------------------
public list[tuple[real threshold, str rating]] unitSizeSigScale = [
    <10.0,  "++">,
    <30.0,  "+">,
    <60.0,  "o">,
    <100.0, "-">,
    <999999.0, "--">
];

/**
  * Calculate Unit Size metric for the given list of files.
  */
public UnitMetric calculateUnitSize(list[loc] files) {
    list[tuple[loc,Declaration]] units = extractUnits(files);
    list[int] sizes = [];

    for (<_, decl> <- units) {
        int count = 0;

        visit(decl) {
            case Statement _:
                count += 1;
        }
        sizes += (count > 0 ? count - 1 : 0);
    }
    int total = size(sizes);
    real avg = total == 0 ? 0.0 : toReal(sum(sizes)) / total;
    map[str,int] rp = calculateRiskProfile(sizes, unitSizeThresholds);
    str rating = calculateUnitMetricRating(avg, unitSizeSigScale);
    return unitMetric(total, sizes, avg, rp, rating);
}
