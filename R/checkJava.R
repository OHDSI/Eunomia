# Copied from https://github.com/beast-dev/BeastJar/blob/master/R/Utilities.R

#' Determine if Java virtual machine supports Java
#'
#' @description
#' Tests Java virtual machine (JVM) java.version system property to check if version >= 8.
#'
#' @return
#' Returns TRUE if JVM supports Java >= 8.
#'
#' @examples
#' \dontrun{
#' supportsJava8()
#' }
#' @export
supportsJava8 <- function() {
  # return(FALSE)
  javaVersionText <- rJava::.jcall("java/lang/System", "S", "getProperty", "java.version")
  majorVersion <- as.integer(regmatches(javaVersionText,
                                        regexpr(pattern = "^\\d+", text = javaVersionText)))
  if (majorVersion == 1) {
    twoDigitVersion <- regmatches(javaVersionText,
                                  regexpr(pattern = "^\\d+\\.\\d+", text = javaVersionText))
    majorVersion <- as.integer(regmatches(twoDigitVersion,
                                          regexpr("\\d+$", text = twoDigitVersion)))
  }
  support <- majorVersion >= 8
  return(support)
}
