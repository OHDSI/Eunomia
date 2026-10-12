# Export data files from a database(sqlite or duckdb)

Helper function to export data to csv or parquet files from a database
file (sqlite or duckdb).

## Usage

``` r
exportDataFiles(
  dbPath,
  outputFolder,
  outputFormat = "csv",
  dbms = "sqlite",
  verbose = FALSE
)
```

## Arguments

- dbPath:

  The path to the source .sqlite or .duckdb file

- outputFolder:

  The path to the export destination directory

- outputFormat:

  The output format for the files. Supported formats include csv,
  parquet.

- dbms:

  The file-based database system to use: 'sqlite' (default) or 'duckdb'

- verbose:

  Boolean argument controlling verbose debugging output

## Value

No return value, called to export to outputFolder.
