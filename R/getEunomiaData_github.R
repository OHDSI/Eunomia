getEunomiaData <- function(datasetName, cdmVersion = "5.3", pathToDbEunomia = Sys.getenv("DATABASE_EUNOMIA_DATA_FOLDER"), method = "auto", ...) {
  # baseUrl <- "https://github.com/OHDSI/EunomiaDatasets/tree/blob/datasets/" #pathToDbEunomia
  
  if (is.null(pathToDbEunomia) || is.na(pathToDbEunomia) || pathToDbEunomia == "") {
    abort("The pathToDbEunomia argument must be specified. Consider setting the DATABASE_EUNOMIA_DATA_FOLDER environment variable, for example in the .Renviron file.")
  }
  
  if (pathToDbEunomia != Sys.getenv("DATABASE_EUNOMIA_DATA_FOLDER")) {
    if (Sys.getenv("DATABASE_EUNOMIA_DATA_FOLDER") != pathToDbEunomia) {
      inform(paste0(
        "Consider adding `DATABASE_EUNOMIA_DATA_FOLDER='",
        pathToDbEunomia,
        "'` to ",
        path.expand("~/.Renviron"), " and restarting R."
      ))
    }
  }

  # result <- download.file(
  #   url = 'https://github.com/OHDSI/EunomiaDatasets/blob/main/datasets/GiBleed/GiBleed_5.3.zip?raw=true',
  #   destfile = 'GiBleed_5.3.zip',
  #   method = 'auto'
  # )
  
  #saves current working directory, dataset name and version (a single string), and the dataset zip file name string.
  pwd <- getwd()
  datasetNameVersion <- paste0(datasetName, '_', cdmVersion)
  zipName <- paste0(datasetNameVersion, ".zip")
  #downloads the file from github
  result <- download.file(
    url = paste(pathToDbEunomia, datasetName, paste0(zipName, "?raw=true"), sep = '/'),
    destfile = zipName,
    method = method
  )
  
  #unzip(file.path('/Users/starsdliu/OneDrive - Johns Hopkins/OHDSI/eunomiaEnv/GiBleed_5.3.zip'))
  #unzip and read
  extracteddatasetName <- unzip(file.path(paste(pwd, zipName, sep = '/')))
  #moves into the unzipped directory
  setwd(paste0('./', datasetNameVersion))
  #lists all the csv files and import
  temp = list.files(pattern="*.csv")
  for (i in 1:length(temp)) assign(temp[i], read.csv(temp[i]))
  
  unzipSuccess <- extracteddatasetName[1] == temp[1]

  if (result == 0) {
    inform(paste0("Eunomia datasets downloaded and datasets imported"))
  } else {
    abort(paste0("Download and import have failed."))
  }
}

invisible(pathToDbEunomia)
# }