module Duplication

import IO;
import List;
import Set;
import Map;
import String;

// ----------------------------------------------------
// Data structure representing Duplication metrics
// ----------------------------------------------------
data Duplication = duplication(int duplicatedLines, real percentage, str rating);

// ----------------------------------------------------
// SIG Duplication Rating Scale (based on duplicated %)
// ----------------------------------------------------
public list[tuple[real threshold, str rating]] duplicationSigScale = [
    <5.0,    "++">,   
    <10.0,   "+">,    
    <20.0,   "o">,    
    <40.0,   "-">,    
    <100.0,  "--">    
];

/**
 * Calculate duplication based on a list of file locations.
 */
public Duplication calculateDuplication(list[loc] locs) {
    list[list[str]] fileLines = [ normalizeLines(f) | loc f <- locs ];
    list[list[list[str]]] allBlocks = [ extractFileBlocks(lines) | list[str] lines <- fileLines ];
    int duplicatedLines = countDuplicatedLines(allBlocks, fileLines) / 2;

    int totalLines = 0;
    for (list[str] ls <- fileLines) {
        totalLines += size(ls);
    }
    real percent = totalLines == 0 ? 0.0 : ((duplicatedLines) * 100.0) / totalLines;
    str rating = calculateDuplicationRank(percent);
    return duplication(duplicatedLines, percent, rating);
}

/**
 * Normalize lines by removing comments, blank lines, and extra whitespace.
 */
public list[str] normalizeLines(loc file) {
    list[str] result = [];
    bool inBlock = false;

    for (str raw <- readFileLines(file)) {
        str line = trim(raw);

        if (inBlock) {
            if (contains(line, "*/")) {
                inBlock = false;
            }
            continue;
        }
        if (startsWith(line, "/*")) {
            if (!contains(line, "*/")) {
                inBlock = true;
            }
            continue;
        }
        if (line == "" || startsWith(line, "//")) {
            continue;
        }
        str original = line;
        line = replaceAll(line, "\\s+", " ");
        line = trim(line);
        result += [line];
    }
    return result;
}

/**
 * Extract blocks of lines from a list of lines.
 */
public list[list[str]] extractFileBlocks(list[str] lines) {
    int blockSize = 6;
    list[list[str]] blocks = [];

    if (size(lines) < blockSize) {
        return blocks;
    }
    for (int i <- [0 .. size(lines) - blockSize]) {
        list[str] block = [ lines[j] | int j <- [i .. i + blockSize - 1] ];
        blocks += [block];
    }
    return blocks;
}

/**
 * Count duplicated lines across all files based on extracted blocks.
 */
public int countDuplicatedLines(list[list[list[str]]] allBlocks,list[list[str]] fileLines) {
    int blockSize = 6;
    map[list[str], list[tuple[int,int]]] occurrences = ();

    for (int f <- [0 .. size(allBlocks) - 1]) {
        list[list[str]] blocks = allBlocks[f];

        if (size(blocks) == 0) {
            continue; // skip files with <6 lines
        }
        for (int i <- [0 .. size(blocks) - 1]) {
            list[str] block = blocks[i];
            list[tuple[int,int]] old = occurrences[block] ? [];
            occurrences[block] = old + [<f, i>];
        }
    }

    list[set[int]] dupLinesPerFile = [];
    for (int _ <- [0 .. size(fileLines) - 1]) {
        dupLinesPerFile += [{}];
    }
    for (list[str] block <- domain(occurrences)) {
        list[tuple[int,int]] occ = occurrences[block];

        if (size(occ) < 2) {
            continue;
        }
        for (<file, line> <- occ) {
            for (int k <- [0 .. blockSize - 1]) {
                int idx = line + k;

                if (idx < size(fileLines[file])) {
                    dupLinesPerFile[file] = dupLinesPerFile[file] + { idx };
                }
            }
        }
    }

    int duplicateLines = 0;
    for (int f <- [0 .. size(dupLinesPerFile) - 1]) {
        duplicateLines += size(dupLinesPerFile[f]);
    }
    return duplicateLines;
}

/*
 * SIG Duplication Ranking (thresholds recognized by the SIG model)
 */
public str calculateDuplicationRank(real avg) {
    for (<t, r> <- duplicationSigScale) {
        if (avg <= t) {
            return r;
        }
    }
    return last([ r | <_, r> <- duplicationSigScale ]);
}