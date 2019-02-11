# These are the temporary instructions for getting the right dependencies:

devtools::install_github("r-dbi/RSQLite") # Need latest develop version for ROW_NUMBER() support
devtools::install_github("ohdsi/SqlRender", ref = "sqlite")
devtools::install_github("ohdsi/DatabaseConnector", ref = "sqlite")
