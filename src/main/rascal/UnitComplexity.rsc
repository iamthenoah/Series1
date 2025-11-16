module UnitComplexity

import UnitMetricHelper;

import lang::java::m3::Core;
import lang::java::m3::AST;

import List;
import util::Math;

// ----------------------------------------------------
// Cyclomatic Complexity Thresholds (SIG)
// ----------------------------------------------------
public map[str, tuple[int min, int max]] complexityThresholds = (
    "low"      : <0, 10>,
    "moderate" : <11, 20>,
    "high"     : <21, 50>,
    "veryHigh" : <51, 999999>
);

// ----------------------------------------------------
// SIG Rating scale based on AVERAGE complexity
// ----------------------------------------------------
public list[tuple[real threshold, str rating]] complexitySigScale = [
    <10.0,  "++">,
    <20.0,  "+">,
    <50.0,  "o">,
    <100.0, "-">,
    <999999.0, "--">
];

/**
  * Calculate Unit Complexity metric for the given list of files.
  */
public UnitMetric calculateUnitComplexity(list[loc] files) {
    list[tuple[loc,Declaration]] units = extractUnits(files);
    list[int] complexities = [];

    for (<_, decl> <- units) {
        complexities += countComplexity(decl);
    }
    int total = size(complexities);
    real avg = total == 0 ? 0.0 : toReal(sum(complexities)) / total;
    map[str,int] rp = calculateRiskProfile(complexities, complexityThresholds);
    str rating = calculateUnitMetricRating(avg, complexitySigScale);
    return unitMetric(total, complexities, avg, rp, rating);
}

/**
  * Count cyclomatic complexity for a given method or constructor declaration.
  */
public int countComplexity(Declaration d) {
    int cc = 1; // base

    visit(d) {
        case \if(_, _)              : cc += 1;
        case \if(_, _, _)           : cc += 1;
        case \case(_)               : cc += 1;
        case \do(_, _)              : cc += 1;
        case \while(_, _)           : cc += 1;
        case \for(_, _, _)          : cc += 1;
        case \for(_, _, _, _)       : cc += 1;
        case \foreach(_, _, _)      : cc += 1;
        case \catch(_, _)           : cc += 1;
        case \continue()            : cc += 1;
        case \continue(_)           : cc += 1;
    }
    return cc;
}