% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Connection.R
\name{getEunomiaConnectionDetails}
\alias{getEunomiaConnectionDetails}
\title{Get Default Eunomia Connection Details}
\usage{
getEunomiaConnectionDetails(
  databaseFile = tempfile(fileext = ".sqlite"),
  dbms = "sqlite"
)
}
\arguments{
\item{databaseFile}{The path where the database file will be copied to. By default, the database will
be copied to a temporary folder, and will be deleted at the end of the R session.}

\item{dbms}{The target dialect, by default "sqlite".}
}
\value{
A ConnectionDetails object, to be used with the \code{DatabaseConnector} package.
}
\description{
Creates a copy of the default (GiBleed) Eunomia database, and provides details for connecting to
that copy. Function provides backwards compatibility to prior releases of Eunomia default (GiBleed)
dataset
}
