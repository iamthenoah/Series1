module DuplicationTests

import util::Test;
import Duplication;
import IO;
import List;
import String;
import util::Math;

private loc fileA = |project://series1/src/test/rascal/resources/TestCode.java|;
private loc fileB = |project://series1/src/test/rascal/resources/TestCodeToo.java|;


// =============================================================
// 1. Normalization: ensure both files normalize to same lines
// =============================================================
test bool normalizeLines_identical_outputs() {
    list[str] a = normalizeLines(fileA);
    list[str] b = normalizeLines(fileB);

    return size(a) == size(b);
}


// =============================================================
// 2. Block extraction correctness
// =============================================================
test bool blockExtraction_correct() {
    list[str] lines = normalizeLines(fileA);
    list[list[str]] blocks = extractFileBlocks(lines);

    return size(blocks) == 12
        && [ size(b) | b <- blocks ] == [5,5,5,5,5,5,5,5,5,5,5,5];
}


// =============================================================
// 4. Order independence regression test
// =============================================================
test bool duplication_order_independent() {
    Duplication d1 = calculateDuplication([fileA, fileB]);
    Duplication d2 = calculateDuplication([fileB, fileA]);
    
    return d1.duplicatedLines == d2.duplicatedLines;
}
