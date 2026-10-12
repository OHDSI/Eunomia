# Load data files into a database(sqlite or duckdb)

Load data from csv or parquet files into a database file (sqlite or
duckdb).

## Usage

``` r
loadDataFiles(
  dataPath,
  dbPath,
  inputFormat = "csv",
  cdmVersion = "5.5",
  cdmDatabaseSchema = "main",
  dbms = "sqlite",
  verbose = FALSE,
  overwrite = FALSE
)
```

## Arguments

- dataPath:

  The path to the directory containing CDM source files (csv or parquet)

- dbPath:

  The path to the .sqlite or .duckdb file that will be created

- inputFormat:

  The input format of the files to load. Supported formats include csv,
  parquet.

- cdmVersion:

  The CDM version to create in the resulting database. Supported
  versions are 5.3, 5.4, and 5.5

- cdmDatabaseSchema:

  The schema in which to create the CDM tables. Default is main.

- dbms:

  The file-based database system to use: 'sqlite' (default) or 'duckdb'

- verbose:

  Provide additional logging details during execution.

- overwrite:

  Remove and replace an existing data set.

## Value

No return value, loads data into database file.
