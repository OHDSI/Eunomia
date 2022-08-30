

# install.packages("DatabaseConnector")

cd <- Eunomia::getEunomiaConnectionDetails()

csvPath <- here::here("extras", "EunomiaCdm")
unlink(csvPath, recursive = TRUE)
Eunomia::exportToCsv(csvPath)
csvPaths <- list.files(csvPath, full.names = T)

duckdbPath <- here::here("EunomiaCdms", "duckdb", "cdm.duckdb")
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = duckdbPath)

library(dplyr)
for(p in csvPaths) {
  table_name <- tolower(stringr::str_remove(basename(p), ".csv$"))
  print(paste("loading", p))
  table <- readr::read_csv(p)
  colnames(table) <- tolower(colnames(table))
  # table <- mutate(table, across(matches("_id"), ~ifelse(is.numeric(.), as.integer(.), .)))
  DBI::dbWriteTable(con, table_name, table, overwrite = TRUE)
  # sql <- glue::glue("CREATE TABLE {tolower(table_name)} AS SELECT * FROM '{nm}';")
  # DBI::dbExecute(con, sql)
}

tables <- DBI::dbListTables(con)
for (tbl in tables) {
  print(tibble::tibble(DBI::dbGetQuery(con, paste("select * from ", tbl, "limit 10"))))
}



DBI::dbGetQuery(con, "select * from concept") %>% tibble()

DBI::dbDisconnect(con, shutdown = TRUE)
unlink(csvPath)

o <- setwd(here::here("EunomiaCdms", "duckdb"))
tar("cdm.duckdb.tar.xz", "cdm.duckdb", compression = "xz")
setwd(o)
untar(here::here("EunomiaCdms", "duckdb", "cdm.duckdb.tar.xz"), exdir = here::here("ex"))

unlink(here::here("EunomiaCdms", "duckdb", "cdm.duckdb"))
