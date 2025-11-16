module Volume

import IO;
import List;
import Set;
import Map;
import String;

// ----------------------------------------------------
// Data structure representing Volume metrics
// ----------------------------------------------------
data Volume = volume(int code, int comment, int blank, int total, str rating);

// ----------------------------------------------------
// SIG Volume Rating Scale (based on total LOC)
// ----------------------------------------------------
public list[tuple[real threshold, str rating]] volumeSigScale = [
    <66000.0,   "++">,   
    <246000.0,  "+">,    
    <665000.0,  "o">,    
    <1310000.0, "-">,    
    <999999999.0, "--">  
];

/*
 * Count volume based on a list of file locations.
 * Processes each file to classify lines as code, comment, or blank.
 */
public Volume calculateVolume(list[loc] locs) {
    int codeLines = 0;
    int commentLines = 0;
    int blankLines = 0;
    int totalLines = 0;
    
    for (currentLocation <- locs) {
        <c, cm, b, t> = processFile(currentLocation);
        codeLines += c;
        commentLines += cm;
        blankLines += b;
        totalLines += t;
    }
    str rating = calculateVolumeRank(codeLines);
    return volume(codeLines, commentLines, blankLines, totalLines, rating);
}

/*
 * Process a single file and classify its lines
 */
public tuple[int code, int comment, int blank, int total] processFile(loc fileLoc) {
    int codeCount = 0;
    int commentCount = 0;
    int blankCount = 0;
    int totalCount = 0;
    bool inMultiLineComment = false;
    
    for (line <- readFileLines(fileLoc)) {
        totalCount += 1;
        str trimmedLine = trim(line);
        
        if (trimmedLine == "") {
            blankCount += 1;
        } else if (isCommentLine(trimmedLine, inMultiLineComment)) {
            commentCount += 1;
            inMultiLineComment = updateCommentState(trimmedLine, inMultiLineComment);
        } else {
            codeCount += 1;
            // Check if code line ends with start of multi-line comment
            if (endsWith(trimmedLine, "/*")) {
                inMultiLineComment = true;
            }
        }
    }
    return <codeCount, commentCount, blankCount, totalCount>;
}

/*
 * Check if a line is a comment
 */
public bool isCommentLine(str line, bool inMultiLine) {
    return inMultiLine 
        || startsWith(line, "//")
        || startsWith(line, "/*")
        || startsWith(line, "*")
        || startsWith(line, "*/")
        || endsWith(line, "*/");
}

/*
 * Update multi-line comment state based on current line
 */
public bool updateCommentState(str line, bool currentState) {
    if (startsWith(line, "/*") && !endsWith(line, "*/")) {
        return true;
    }
    if (startsWith(line, "*/") || endsWith(line, "*/")) {
        return false;
    }
    return currentState;
}

/*
 * SIG Volume Ranking (thresholds recognized by the SIG model)
 */
public str calculateVolumeRank(int lines) {
    for (<t, r> <- volumeSigScale) {
        if (lines <= t) {
            return r;
        }
    }
    return last([ r | <_, r> <- volumeSigScale ]);
}