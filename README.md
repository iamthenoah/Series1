## Series1

### Running

- For HSQLDB:

```bash
import Main;

Main::main(|project://hsqldb-2.3.1|);
```

- For SmallSQL:

```bash
import Main;

Main::main(|project://smallsql0.21_src|);
```

### Output

The tool prints a structured report:

- Volume metrics
- Duplication metrics
- Unit size + risk profile
- Unit complexity + risk profile
- SIG ratings for each metric (and Maintainability)

### Testing

For testing, we focus on the key raw metric used to define maintainability scores.

- Open a new Rascal terminal

```bash
import util::Test;

runTests("VolumeTests")
runTests("DuplicationTests")
runTests("UnitSizeTests")
runTests("UnitComplexityTests")
```
