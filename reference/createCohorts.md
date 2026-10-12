# Construct cohorts

Creates a set of predefined cohorts in a cohort table. WARNING: this
will delete all existing cohorts in the table!

## Usage

``` r
createCohorts(
  connectionDetails,
  cdmDatabaseSchema = "main",
  cohortDatabaseSchema = "main",
  cohortTable = "cohort"
)
```

## Arguments

- connectionDetails:

  The connection details to connect to the (Eunomia) database.

- cdmDatabaseSchema:

  Deprecated. The cdm must be created in the main schema.

- cohortDatabaseSchema:

  Deprecated. The cohort table will be created in the main schema.

- cohortTable:

  Deprecated. Cohort table will be named "cohort".

## Value

A data frame listing all created cohorts.
