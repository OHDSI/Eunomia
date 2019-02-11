Eunomia
=======

Eunomia is a standard dataset in the Common Data Model for testing and demonstration purposes


Features
========
- To add

Examples
========

```R
library(Eunomia)
connectionDetails <- getEunomiaConnectionDetails()
connection <- connect(connectionDetails)
querySql(connection, "SELECT COUNT(*) FROM person;")
# 12345
disconnect(connection)
```

Technology
============
Eunomia is an R package containing a SQLite database. 

System Requirements
============
Requires R 

Installation
=============
1. The DatabaseConnector and SqlRender packages require Java. Java can be downloaded from
<a href="http://www.java.com" target="_blank">http://www.java.com</a>. Once Java is installed, ensure that Java is being pathed correctly. Under environment variables in the control panel, ensure that the jvm.dll file is added correctly to the path.
2. In R, use the following commands to download and install CohortMethod:

  ```r
  install.packages("drat")
  drat::addRepo("OHDSI")
  install.packages("Eunomia")
  ```
  
User Documentation
==================
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

Under development. Do not use.
