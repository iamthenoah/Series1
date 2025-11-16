## **1. Overview of Implemented Metrics**

In this assignment we implemented four metrics that together give a basic picture of maintainability: **Volume**, **Unit Size**, **Unit Complexity**, and **Duplication**. These metrics follow the ideas from the Software Improvement Group (SIG), where simple source‑code properties are used as indicators for how easy a system is to understand and change.

Each metric produces both a raw value and an aggregated view. For Unit Size and Unit Complexity we also build risk profiles by grouping units into simple buckets (small, medium, large, very large / low, moderate, high, very high). The actual ratings that feed into maintainability are based on the _average_ size or complexity.

The implementation tries to stay close to SIG’s practical model: collect objective counts, classify them with clear rules, and aggregate them into final ratings for the different maintainability aspects.

---

## **2. Design & Implementation Details**

### **2.1 Volume**

Volume is meant to reflect how much code developers need to deal with. More code usually means more effort to read, navigate, debug, and change.

To compute Volume we:

- Read all Java files from the M3 model.
- For each line we classify it as **code**, **comment**, or **blank**.
- We keep track of separate counters for each of these three categories and also the total number of lines.

We treat comment lines quite precisely. A line is a comment if it:

- Is inside a multi‑line comment (`/* ... */`), or
- Starts with `//`, or
- Starts with `/*`, `*`, or `*/`, or
- Ends with `*/`.

We omit a separate type (hybrid) for a comment at the end of the line of code, as it would not influence the results of the classification.

We keep a simple `inMultiLineComment` flag to follow comment blocks that span multiple lines. Unlike the normalization step in the duplication metric, here we do _not_ remove comment or blank lines; we just classify them. The **code** line count is then used to look up a SIG‑style rating on a fixed scale (very small systems get `++`, very large systems get `--`).

This rating later contributes to the Changeability aspect.

---

### **2.2 Unit Size**

Unit Size reflects how large individual units are. In our implementation a unit is a **method or constructor** declaration; we look at both kinds.

The steps are:

1. Use the Java M3 AST to extract all method and constructor declarations from each file.
2. For each declaration, visit its body and count `Statement` nodes.
3. After counting, we store `count - 1` if there is at least one statement, or `0` otherwise. This subtraction avoids counting the outermost block itself and makes empty bodies show up as size 0.

This gives us a list of sizes for all units.

We then classify each unit into a size bucket using the thresholds from the code:

- **small**: 0–10 statements
- **medium**: 11–30
- **large**: 31–60
- **veryLarge**: 61+

These buckets roughly correspond to low, moderate, high, and very high risk. The risk profile is just a count of how many units fall into each bucket.

However, the **rating** that we actually use later is based on the _average_ unit size. We compare the average against another fixed scale and assign one of the five SIG‑style ratings (`++`, `+`, `o`, `-`, `--`).

Unit Size feeds into all three aspects (Analysability, Changeability, and Testability) through different weights.

---

### **2.3 Unit Complexity**

Complexity shows how difficult it is to follow the logic inside a unit. The basic idea is that straight‑line code is easier to reason about, while code with many decisions, branches, and loops is harder to understand and test.

We compute a simplified **cyclomatic complexity** score for each method or constructor:

1. Start with a base value of 1.
2. Walk the AST of the declaration and add 1 for each of the following constructs:
   - `if` (with or without `else`)
   - `case` labels in a `switch`
   - `do { } while`
   - `while` loops
   - `for` loops (both three‑part and enhanced forms)
   - `foreach`
   - `catch` blocks
   - `continue` statements (with or without a label)

At the moment we do **not** count conditional operators (`?:`) or logical operators (`&&`, `||`) directly, even though they would also influence control flow. Extending the visitor to include these nodes would make the metric closer to a full cyclomatic complexity measure.

Once we have a complexity value for each unit, we classify them into buckets using:

- **low**: 0–10
- **moderate**: 11–20
- **high**: 21–50
- **veryHigh**: 51+

Again, we build a risk profile (how many units in each bucket), but the **rating** used for maintainability is based on the _average_ complexity over all units, compared against a fixed scale from `++` to `--`.

Complexity mainly influences Analysability and Testability.

---

### **2.4 Duplication**

Duplication identifies pieces of code that appear more than once. Repeated code means developers have to change several places when fixing a bug, and it is easy to miss one of them.

We use a **line‑based sliding window** approach with the following steps:

1. For each file we read all lines and trim whitespace.
2. We remove comments and empty lines:
   - If a line starts a block comment (`/*`) without ending it, we set a flag and skip lines until we see `*/`.
   - We skip lines inside such a block.
   - We also skip single‑line comments starting with `//`.
3. From this cleaned list we build windows of **6 consecutive lines** (so the block size `k` is 6, not 5).
4. For each 6‑line block we store it in a map that records all locations where that exact block occurs.

After collecting all blocks from all files, we look at the blocks that appear at least twice. For each occurrence of such a block we mark the covered line indices as duplicated in a set for that file. At the end we count how many unique duplicated line indices there are per file and sum them.

Because each duplicated region appears in at least two places, we would effectively count the same logical duplicated lines twice. To correct for this, we divide the duplicated line count by 2 before reporting it. (maybe add that just divide by 2 could be improved) We then divide by the total number of normalized lines to get the **duplication percentage**, and we map that percentage to a `++`–`--` rating using a simple threshold table.

Duplication contributes strongly to Changeability and also plays a role in Analysability in our weighting scheme.

---

## **3. SIG Scoring Model Implementation**

To turn raw metric values into quality scores, we follow the SIG‑style structure:

> metric values → ratings → maintainability aspects → overall maintainability

### **From raw metrics to ratings**

- **Volume**  
  We use the total number of code lines and compare it to a fixed scale. Very small systems get `++`, medium‑sized systems get ratings in the middle, and very large systems slide towards `--`.

- **Duplication**  
  We use the duplication percentage and compare it to another scale. Low duplication gets `++`, and high duplication gets `--`.

- **Unit Size** and **Unit Complexity**  
  For these we first compute the _average_ size and _average_ complexity across all units. We then compare each average value against its own scale to get a rating between `++` and `--`. The risk profiles (buckets) do not change the rating directly, but if many units are large or complex, the average will naturally go up.

Internally we convert these ratings to numeric scores so we can combine them:

- `++` → 4
- `+` → 3
- `o` → 2
- `-` → 1
- `--` → 0

### **From ratings to maintainability aspects**

We compute three aspects using weighted averages of these numeric scores:

- **Analysability**  
  Uses Unit Size, Unit Complexity, and Duplication, with equal weights (1/3 each).

- **Changeability**  
  Uses all four metrics:

  - Unit Size: 0.30
  - Unit Complexity: 0.20
  - Duplication: 0.30
  - Volume: 0.20

- **Testability**  
  Uses Unit Size and Unit Complexity, each with weight 0.50.

For each aspect we multiply every metric score by its weight, sum them, and get a real number between 0 and 4. We then map this back to a rating:

- ≥ 3.5 → `++`
- ≥ 2.5 → `+`
- ≥ 1.5 → `o`
- ≥ 0.5 → `-`
- otherwise → `--`

### **Overall maintainability**

To get overall maintainability we:

1. Convert the ratings of Analysability, Changeability, and Testability back to scores (0–4).
2. Average these three scores with equal weights (1/3 each).
3. Map the result again to `++`, `+`, `o`, `-`, or `--` using the same score thresholds as above.

So in the end we stay with the familiar five‑step SIG scale, but under the hood we just use simple weighted averages of the individual metric ratings.

---

## **4. Validation Strategy**

Because the assignment is mainly about implementing the metrics, our validation is practical and lightweight. We used three kinds of checks.

### **1. Manual sanity checks**

For small Java files with known structure, we checked that:

- Volume matched our manual count of code lines, while comment and blank line counts also looked reasonable.
- Unit Size matched the number of visible statements in a method once we applied the same counting rules.
- Complexity went up when we added more `if`, `case`, or loop constructs.
- Duplication detected obviously copy‑pasted blocks.

These checks gave us confidence that the basic logic behaves as expected.

### **2. Cross‑checking against IDE tools**

For Volume and Complexity we compared some results against IntelliJ’s built‑in metrics. The exact numbers were not identical, because the tools use slightly different rules for what counts as a line of code or a decision point. However, the trends were similar: larger and more tangled classes scored higher on both tools.

### **3. Spot‑checking risk profiles**

We also crafted a few methods on purpose:

- A tiny method with 3 statements
- A medium method with about 25 statements
- A very large method with more than 120 statements

The size and complexity buckets behaved as we expected. For duplication, we tested two files that share the same 7‑line block. The 6‑line windows inside that block were detected as duplicates, and when we changed one line, duplication dropped to zero.

Overall, validation focused on “does this make sense?” rather than formal proofs, which fits the simple and practical nature of this model.

---

## **5. Threats to Validity**

Several factors can limit how accurate or general our results are.

### **1. AST extraction limitations**

If the M3 model cannot parse a file or does not support some Java constructs, some methods or constructors may be missed or analysed incorrectly. This mainly affects Unit Size and Unit Complexity, since they depend on the AST.

### **2. Metric definition differences**

“Lines of code” or “complexity” can be defined in many ways. Our rules, especially for comment handling and complexity counting, may differ from professional tools. This makes it harder to compare scores directly across tools or reports.

### **3. Duplication simplification**

The sliding‑window approach may:

- Miss clones if developers copy code but insert extra blank lines or comments in between.
- Overcount repeated boilerplate patterns that happen to be the same 6‑line sequence.

A more advanced clone detector (for example token‑based or AST‑based) would reduce these problems.

### **4. Calibration differences**

SIG uses a large benchmark set to calibrate thresholds. Our thresholds are hand‑picked and only roughly inspired by their ranges. This means the ratings are good for relative comparisons between projects analysed with _this_ tool, but the absolute labels (“good”, “bad”) should be taken with care.

---

## **6. Results Summary for smallsql & hsqldb**

We applied the four metrics to **smallsql** and **hsqldb**. Here is some of the results along with an assessment (for a more detailed overview of the SIG results, please refer to the output files directly).

### **smallsql0.21_src Analysis**

**Volume Analysis**

- **Code LOC**: 24,049
- **Comment LOC**: 8,980 (37.3% comment ratio)
- **Total LOC**: 38,423
- **SIG Rating**: ++ (Excellent)

**Assessment**: The project maintains optimal size with strong comment coverage, whcih means they are using good documentation practices.

**Duplication Analysis**

- **Duplicated Lines**: 1,710
- **Percentage**: 7.1%
- **SIG Rating**: + (Good)

**Assessment**: Duplication levels are controlled and within an acceptable limit.

**Unit Size Distribution**

- **Total Units**: 2,415
- **Average Size**: 7.1 LOC
- **SIG Rating**: ++ (Excellent)
- **Risk Profile**: 83.3% small units, only 1.0% very large units

**Assessment**: Exceptional size distribution with minimal large units, promoting readability.

**Unit Complexity Analysis**

- **Total Units**: 2,415
- **Average Complexity**: 2.5
- **SIG Rating**: ++ (Excellent)
- **Risk Profile**: 96.7% low complexity, only 0.2% very high complexity

**Assessment**: Outstanding complexity management with nearly all units in low complexity category.

**Maintainability Aspects**

- **Analysability**: ++
- **Changeability**: ++
- **Testability**: ++
- **Overall Maintainability**: ++

---

### **hsqldb-2.3.1 Analysis**

**Volume Analysis**

- **Code LOC**: 172,360
- **Comment LOC**: 74,938 (43.5% comment ratio)
- **Total LOC**: 304,127
- **SIG Rating**: + (Good)

**Assessment**: Large-scale project with comment coverage. Due to the size of this project, there are going to be some challenges when it comes to maintainence.

**Duplication Analysis**

- **Duplicated Lines**: 20,848
- **Percentage**: 12.1%
- **SIG Rating**: o (Adequate)

**Assessment**: Duplication levels are concerning and can represent significant technical debt requiring refactoring.

**Unit Size Distribution**

- **Total Units**: 11,032
- **Average Size**: 11.1 LOC
- **SIG Rating**: + (Good)
- **Risk Profile**: 74.0% small units, 2.9% very large units

**Assessment**: Generally good size distribution, though the 2.9% very large units warrant attention.

**Unit Complexity Analysis**

- **Total Units**: 11,032
- **Average Complexity**: 3.2
- **SIG Rating**: ++ (Excellent)
- **Risk Profile**: 95.3% low complexity, 0.3% very high complexity

**Assessment**: Excellent complexity control despite project scale, with strong adherence to simplicity principles.

**Maintainability Aspects**

- **Analysability**: +
- **Changeability**: +
- **Testability**: ++
- **Overall Maintainability**: +

---

### **Comapring both results**

Overall, hsqldb is larger and more complex, while smallsql is more compact but shows some duplication in utility code.

| Metric                  | smallsql            | hsqldb                         |
| ----------------------- | ------------------- | ------------------------------ |
| Volume (LOC)            | lower               | much higher                    |
| Unit Size profile       | mostly small/medium | mix of medium/large            |
| Unit Complexity profile | mostly low          | several high/veryHigh          |
| Duplication %           | noticeable in utils | some, but lower proportionally |

### **Interpretation**

**Volume:**  
hsqldb naturally scores higher because it is a full‑featured SQL engine with more functionality. More code means more maintenance effort.

**Unit Size:**  
smallsql tends to have shorter, straightforward methods and constructors. hsqldb contains several large units that handle parsing and query execution. These push more units into the higher size buckets.

**Complexity:**  
Similarly, hsqldb contains deeper logic and more branching. Its complexity profile shows more high‑risk units than smallsql.

**Duplication:**  
smallsql has a few repeated blocks, probably due to manual code reuse instead of shared helpers. hsqldb has duplication as well, but as a percentage of its total size it is lower.

### **Maintainability scores**

smallsql ends up with better Analysability and Testability because its units are smaller and simpler. hsqldb does worse on these two aspects due to larger size and higher complexity. Changeability is affected by all four metrics, but the extra volume and complexity in hsqldb mostly cancels out its slightly better duplication. Overall maintainability is higher for smallsql because the system is smaller and easier to inspect.

---

## **7. Reflection & Future Improvements**

This assignment shows how much insight we can already get from simple metrics. Even without very advanced analysis, the four metrics highlight clear maintainability risks. Volume hints at how much code there is to understand, while Size and Complexity point out the most challenging parts. Duplication reveals places where keeping behaviour consistent across copies takes extra effort.

The main limitation of our implementation is that the thresholds and weights are only approximate. A more realistic scoring model would calibrate them using many real‑world systems, as SIG does. That would make the ratings more trustworthy and less dependent on our own guesses.

Another improvement would be to use a token‑based or AST‑based clone detector, so duplication is measured more precisely. For complexity, building a real control‑flow graph and counting all decision points (including `?:`, `&&`, and `||`) would get us closer to the textbook definition.

Still, even in this simplified form, the implementation gives useful and understandable feedback. It follows the SIG idea of measuring objectively, classifying consistently, and interpreting the results in terms of everyday developer effort.
