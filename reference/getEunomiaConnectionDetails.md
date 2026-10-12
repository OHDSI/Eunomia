# Get Default Eunomia Connection Details

Creates a copy of the default GiBleed CDM v5.5 Eunomia database, and
provides details for connecting to that copy. Function provides
backwards compatibility to prior releases of the Eunomia default GiBleed
dataset.

## Usage

``` r
getEunomiaConnectionDetails(
  databaseFile = tempfile(fileext = ".sqlite"),
  dbms = "sqlite",
  overwrite = FALSE
)
```

## Arguments

- databaseFile:

  The path where the database file will be copied to. By default, the
  database will be copied to a temporary folder, and will be deleted at
  the end of the R session.

- dbms:

  The target dialect, by default "sqlite".

- overwrite:

  Control whether the existing archive file will be overwritten should
  it already exist.

## Value

A ConnectionDetails object, to be used with the `DatabaseConnector`
package.
