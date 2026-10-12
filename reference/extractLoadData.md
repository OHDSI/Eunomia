# Extract the Eunomia data files and load into a database Extract files from a .ZIP file and creates a OMOP CDM database that is then stored in the same directory as the .ZIP file.

Extract the Eunomia data files and load into a database Extract files
from a .ZIP file and creates a OMOP CDM database that is then stored in
the same directory as the .ZIP file.

## Usage

``` r
extractLoadData(
  from,
  to,
  dbms = "sqlite",
  cdmVersion = "5.5",
  inputFormat = "csv",
  verbose = FALSE
)
```

## Arguments

- from:

  The path to the .ZIP file that contains the csv CDM source files

- to:

  The path to the .sqlite or .duckdb file that will be created

- dbms:

  The file based database system to use: 'sqlite' (default) or 'duckdb'

- cdmVersion:

  The version of the OMOP CDM that are represented in the archive files.

- inputFormat:

  The format of the files expected in the archive. (csv or parquet)

- verbose:

  Provide additional logging details during execution.

## Value

No return value, called to load archive into a database file.

## See also

[`downloadEunomiaData`](https://ohdsi.github.io/Eunomia/reference/downloadEunomiaData.md)

## Examples

``` r
if (FALSE) { # \dontrun{
extractLoadData("c:/strategusData/GiBleed_5.5.zip")
} # }
```
