Eunomia 2.0
=============
Changes
- Updated package to no longer contain a dataset rather facilite access to sample datasets
  stored in the https://github.com/OHDSI/EunomiaDatasets repository
- Backward compatibility maintained with getEunomiaConnectionDetails function
- New function added for getDatabaseFile
- Embedded sample dataset removed
- Remove dependency on DatabaseConnector and Java

Eunomia 1.0.2
=============

Changes
- switch to readr::write_csv for proper concept_id handling
- added gender concepts to concept table

Eunomia 1.0.1
=============

Changes

- Using xz compression to further reduce package size.


Eunomia 1.0.0
=============

Initial release
