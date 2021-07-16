# Code used to move the data from one format to another
# In this case moving from plain SQLite to SQLite with extended types (including dates)
library(Eunomia)
connectionDetails <- getEunomiaConnectionDetails()
oldDb <- connect(connectionDetails)

# New data target:
library(RSQLite)
unlink( "cdm.sqlite")
newDb <- dbConnect(RSQLite::SQLite(), "cdm.sqlite", extended_types = TRUE)

# Copy data:
# tableName <- "OBSERVATION_PERIOD"
for (tableName in getTableNames(oldDb, "main")) {
  message("Copying table ", tableName)
  table <- querySql(oldDb, sprintf("SELECT * FROM main.%s;", tableName))
  dbCreateTable(conn = newDb,
                name = tableName,
                fields = table)
  dbAppendTable(conn = newDb,
                name = tableName,
                value = table)
  tableCheck <- dbReadTable(newDb, tableName)
  if (!all.equal(table, tableCheck)) {
    stop("Problem uploading table ", tableName)
  }
}
dbDisconnect(newDb)
disconnect(oldDb)
