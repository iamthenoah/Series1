module Main

import lang::java::m3::Core;
import lang::java::m3::AST;

import IO;
import Map;
import List;
import Set;
import String;
import util::Math;

import Volume;
import Duplication;
import UnitSize;
import UnitComplexity;
import UnitMetricHelper;
import Maintainability;

/*
 * Entry point for running the analysis on a given project.
 * The `project` argument must refer to a Rascal project location.
 *
 * Example project locations:
 * |project://hsqldb-2.3.1|
 * |project://smallsql0.21_src|
 * |project://se-test-project|
 */
public int main(loc project) {
    M3 model = createM3FromMavenProject(project);
    list[loc] javaFiles = toList(files(model));

    Volume vol      = Volume::calculateVolume(javaFiles);
    Duplication dup = Duplication::calculateDuplication(javaFiles);
    UnitMetric us   = UnitSize::calculateUnitSize(javaFiles);
    UnitMetric uc   = UnitComplexity::calculateUnitComplexity(javaFiles);

    // once we have all metrics, calculate maintainability aspects
    map[str, str] mn = Maintainability::calculateAspectRatings(vol, dup, us, uc);

    println();
    println("======= Java Project Analysis =======");
    println();
    println("- Analyzing project: <project> (<size(javaFiles)> Java files)");
    println();
    println("--- Volume");
    println();
    printVolume(vol);
    println();
    println("--- Duplication");
    println();
    printDuplication(dup);
    println();
    println("--- Unit Size");
    println();
    printUnitMetric(us, ["small", "medium", "large", "veryLarge"]);
    println();
    println("--- Unit Complexity");
    println();
    printUnitMetric(uc, ["low", "moderate", "high", "veryHigh"]);
    println();
    println("--- Maintainability Aspects");
    println();
    printMaintainabilityScores(mn);
    println();
    println("======= ===================== =======");
    println();

    return 0;
}

// ---------------------------------------------------------
// Printing Utilities
// ---------------------------------------------------------

private void printVolume(Volume vol) {
    println("  Code LOC:                <vol.code>");
    println("  Comment LOC:             <vol.comment>");
    println("  Blank LOC:               <vol.blank>");
    println("  Total LOC:               <vol.total>");
    println("  SIG Rating:              <vol.rating>");
}

private void printDuplication(Duplication dup) {
    println("  Duplicated Lines:        <dup.duplicatedLines>");
    println("  Percentage:              <round(dup.percentage, 0.1)>%");
    println("  SIG Rating:              <dup.rating>");
}

private void printUnitMetric(UnitMetric um, list[str] orderedKeys) {
    int total = um.totalUnits;
    real pct(int n) = total == 0 ? 0.0 : round((n * 100.0) / total, 0.1);

    println("  Total Units:             <total>");
    println("  Average:                 <round(um.average, 0.1)>");
    println("  SIG Rating:              <um.rating>");
    println("");
    println("  Risk Profile:");

    for (k <- orderedKeys) {
        int v = um.riskProfiles[k];
        println("    <k>: <v> (<pct(v)>%)");
    }
}

private void printMaintainabilityScores(map[str, str] aspects) {
    println("  Analysability:           <aspects["analysability"]>");
    println("  Changeability:           <aspects["changeability"]>");
    println("  Testability:             <aspects["testability"]>");
    println("  ---");
    println("  Maintainability:         <aspects["maintainability"]>");
}
