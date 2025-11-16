module Maintainability

import IO;
import Map;
import List;
import util::Math;

import Volume;
import Duplication;
import UnitMetricHelper;
import UnitSize;
import UnitComplexity;

// ===========================================
// Analysability = complexity + size + duplication
// ===========================================
public map[str, real] analysabilityWeights = (
    "unitSize":       1.0/3.0,
    "unitComplexity": 1.0/3.0,
    "duplication":    1.0/3.0
);

// ===========================================
// Changeability = size + duplication + complexity + volume
// ===========================================
public map[str, real] changeabilityWeights = (
    "unitSize":       0.30,
    "unitComplexity": 0.20,
    "duplication":    0.30,
    "volume":         0.20
);

// ===========================================
// Testability = size + complexity
// ===========================================
public map[str, real] testabilityWeights = (
    "unitSize":       0.50,
    "unitComplexity": 0.50
);

// ===========================================
// Maintainability = average of 3 aspects
// ===========================================
public map[str, real] maintainabilityWeights = (
    "analysability":  1.0/3.0,
    "changeability":  1.0/3.0,
    "testability":    1.0/3.0
);

/**
  * Calculate maintainability aspect ratings based on SIG model.
  */
public map[str, str] calculateAspectRatings(Volume vol, Duplication dup, UnitMetric size, UnitMetric comp) {
    map[str, int] baseScores = (
        "volume":         ratingToScore(vol.rating),
        "duplication":    ratingToScore(dup.rating),
        "unitSize":       ratingToScore(size.rating),
        "unitComplexity": ratingToScore(comp.rating)
    );

    real analysabilityScore = weightedScore(baseScores, analysabilityWeights);
    real changeabilityScore = weightedScore(baseScores, changeabilityWeights);
    real testabilityScore   = weightedScore(baseScores, testabilityWeights);

    str analysabilityRating = scoreToRating(analysabilityScore);
    str changeabilityRating = scoreToRating(changeabilityScore);
    str testabilityRating   = scoreToRating(testabilityScore);

    map[str,int] aspectsAsScores = (
        "analysability": ratingToScore(analysabilityRating),
        "changeability": ratingToScore(changeabilityRating),
        "testability":   ratingToScore(testabilityRating)
    );
    real maintainabilityScore = weightedScore(aspectsAsScores, maintainabilityWeights);
    str maintainabilityRating = scoreToRating(maintainabilityScore);

    return (
        "analysability":  analysabilityRating,
        "changeability":  changeabilityRating,
        "testability":    testabilityRating,
        "maintainability": maintainabilityRating
    );
}

/**
  * Calculate a weighted score given metric scores and weights.
  */
private real weightedScore(map[str, int] metricScores, map[str, real] weights) {
    real sum = 0.0;
    for (k <- weights) {
        sum += weights[k] * metricScores[k];
    }
    return sum;
}

/**
  * Convert a SIG rating to a numeric score.
  */
private int ratingToScore(str rating) {
    switch (rating) {
        case "++": return 4;
        case "+":  return 3;
        case "o":  return 2;
        case "-":  return 1;
        case "--": return 0;
    }
    return 0;
}

/**
  * Convert a real score to a SIG rating.
  */
private str scoreToRating(real s) {
    if (s >= 3.5) return "++";
    if (s >= 2.5) return "+";
    if (s >= 1.5) return "o";
    if (s >= 0.5) return "-";
    return "--";
}