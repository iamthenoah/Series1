module UnitMetricHelper

import lang::java::m3::Core;
import lang::java::m3::AST;

import IO;
import List;
import Set;
import Map;
import String;
import util::Math;

// ----------------------------------------------------
// Data structure representing a unit-level metric
// ----------------------------------------------------
data UnitMetric = unitMetric(
    int totalUnits,
    list[int] values,
    real average,
    map[str,int] riskProfiles,
    str rating
);

/**
  * Extract method and constructor declarations from the given list of files.
  */
public list[tuple[loc src, Declaration decl]] extractUnits(list[loc] files) {
    list[tuple[loc, Declaration]] units = [];

    for (file <- files) {
        Declaration cu = createAstFromFile(file, true);

        for (Declaration d <- [x | /Declaration x := cu]) {
            if (isMethod(d.decl) || isConstructor(d.decl)) {
                units += <file, d>;
            }
        }
    }
    return units;
}

/**
  * Generic risk profile calculation based on provided thresholds.
  */
public map[str,int] calculateRiskProfile(list[int] values, map[str, tuple[int min, int max]] thresholds) {
    map[str,int] profile = ();

    for (k <- thresholds) {
        profile[k] = 0;
    }
    for (v <- values) {
        for (k <- thresholds) {
            if (v >= thresholds[k].min && v <= thresholds[k].max) {
                profile[k] = profile[k] + 1;
                break;
            }
        }
    }
    return profile;
}

/**
  * Generic unit metric rating calculation based on provided ordered thresholds.
  */
public str calculateUnitMetricRating(real avg, list[tuple[real threshold, str rating]] order) {
    for (<t, r> <- order) {
        if (avg <= t) {
            return r;
        }
    }
    return last([ r | <_, r> <- order ]);
}