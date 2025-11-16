## Series1

### Open the Rascal Console and run:

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
  
