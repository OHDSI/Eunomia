Eunomia
=======

[![Build Status](https://travis-ci.org/OHDSI/Eunomia.svg?branch=master)](https://travis-ci.org/OHDSI/Eunomia)
[![codecov.io](https://codecov.io/github/OHDSI/Eunomia/coverage.svg?branch=master)](https://codecov.io/github/OHDSI/Eunomia?branch=master)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/Eunomia)](https://cran.r-project.org/package=Eunomia)
[![CRAN_Status_Badge](http://cranlogs.r-pkg.org/badges/Eunomia)](https://cran.r-project.org/package=Eunomia)

Eunomia is part of [HADES](https://ohdsi.github.io/Hades/).

Introduction
============
Eunomia is a standard dataset in the OMOP (Observational Medical Outcomes Partnership) Common Data Model (CDM) for testing and demonstration purposes. Eunomia is used for many of the exercises in [the Book of OHDSI](https://ohdsi.github.io/TheBookOfOhdsi/). For functions that require schema name, use 'main'.

Features
========
- Provides a small simulated dataset in the CDM.
- Also includes a subset of the Standardized Vocabularies.
- Interfaces with the DatabaseConnector and SqlRender packages.
- No need to set up a database server. Eunomia runs in your R instance (using SQLite).

Example
=======

```R
library(Eunomia)
connectionDetails <- getEunomiaConnectionDetails()
connection <- connect(connectionDetails)
querySql(connection, "SELECT COUNT(*) FROM person;")
#  COUNT(*)
#1     2694

getTableNames(connection,databaseSchema = 'main')
disconnect(connection)
```

Technology
==========
Eunomia is an R package containing a SQLite database. 

System Requirements
===================
Requires R. Some of the packages required by Eunomia require Java. 

Installation
============

1. See the instructions [here](https://ohdsi.github.io/Hades/rSetup.html) for configuring your R environment, including Java.

2. In R, use the following commands to download and install Eunomia:

  ```r
  install.packages("drat")
  drat::addRepo("OHDSI")
  install.packages("Eunomia")
  ```
  
User Documentation
==================
Documentation can be found on the [package website](https://ohdsi.github.io/Eunomia/).

PDF versions of the documentation are also available:
* Package manual: [Eunomia.pdf](https://raw.githubusercontent.com/OHDSI/Eunomia/master/extras/Eunomia.pdf)

Support
=======
* Developer questions/comments/feedback: <a href="http://forums.ohdsi.org/c/developers">OHDSI Forum</a>
* We use the <a href="https://github.com/OHDSI/Eunomia/issues">GitHub issue tracker</a> for all bugs/issues/enhancements

License
=======
Eunomia is licensed under Apache License 2.0

Development
===========
Eunomia is being developed in R Studio.

### Development status

Ready for use
