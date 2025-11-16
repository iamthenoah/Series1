module VolumeTests

import util::Test;
import IO;
import Volume;

// ------------------------------------------------------------
// Use the real TestCode.java file
// ------------------------------------------------------------
private loc testFile =
    |project://series1/src/test/rascal/resources/TestCode.java|;


// ============================================================
// 1. Hard-number UNIT TESTS for processFile()
// ============================================================

test bool processFile_counts_are_correct() {
    <code, comment, blank, total> = processFile(testFile);

    return
        code == 18
    &&  comment == 6
    &&  blank == 5
    &&  total == 29;
}


// ============================================================
// 2. calculateVolume() should produce the exact same numbers
// ============================================================

test bool calculateVolume_exact_values() {
    Volume v = calculateVolume([testFile]);

    return
        v.code == 18
    &&  v.comment == 6
    &&  v.blank == 5
    &&  v.total == 29;
}


// ============================================================
// 3. SIG Rating correctness
// ============================================================

test bool calculateVolume_rating_correct() {
    Volume v = calculateVolume([testFile]);

    // 18 code lines → "++"
    return v.rating == "++";
}


// ============================================================
// 4. Regression: ensure nothing breaks on repeated parsing
// ============================================================

test bool calculateVolume_stable_on_multiple_calls() {
    Volume a = calculateVolume([testFile]);
    Volume b = calculateVolume([testFile]);

    return a == b; // ensures deterministic processing
}
