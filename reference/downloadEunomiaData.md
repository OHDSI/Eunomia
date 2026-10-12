# Download Eunomia data files

Download the Eunomia data files from
https://github.com/OHDSI/EunomiaDatasets

## Usage

``` r
downloadEunomiaData(
  datasetName,
  cdmVersion = "5.5",
  pathToData = Sys.getenv("EUNOMIA_DATA_FOLDER"),
  overwrite = FALSE,
  verbose = FALSE
)
```

## Arguments

- datasetName:

  The data set name as found on
  https://github.com/OHDSI/EunomiaDatasets. The data set name
  corresponds to the folder with the data set ZIP files

- cdmVersion:

  The OMOP CDM version. This version will appear in the suffix of the
  data file, for example: \<datasetName\>\_\<cdmVersion\>.zip. Default:
  '5.5'

- pathToData:

  The path where the Eunomia data is stored on the file system., By
  default the value of the environment variable "EUNOMIA_DATA_FOLDER" is
  used.

- overwrite:

  Control whether the existing archive file will be overwritten should
  it already exist.

- verbose:

  Provide additional logging details during execution.

## Value

Invisibly returns the destination if the download was successful.

## Examples

``` r
if (FALSE) { # \dontrun{
downloadEunomiaData("GiBleed")
} # }
```
