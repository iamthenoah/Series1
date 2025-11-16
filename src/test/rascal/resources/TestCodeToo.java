package org.example;

public class TestCodeToo {

  public int duplicatedLogic(int x) {
    // initial guard
    if (x == 0) {
      return 0;
    }

    int result = 0;

    // core logic (identical structure)
    for (int i = 0; i < x; i++) {
      result += (i * 2) + 3;
    }

    // additional logic
    if (result > 100) {
      result = result / 2;
    } else {
      result = result * 3;
    }
    return result;
  }
}
