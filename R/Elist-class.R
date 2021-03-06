## Check class conforms to API
.hasMethods <- function(object, my_fun) {
  obj_cl <- class(object)
  if (any(my_fun %in% c("[", "assay"))) {
    if (is(object, "RangedSummarizedExperiment")) {
      return(hasMethod(my_fun, signature = c(class(object), "missing")))
    } else {
      return(hasMethod(my_fun, signature = c(obj_cl, "ANY")))
    }
  }
  return(hasMethod(my_fun, signature = obj_cl))
}

.getNameErr <- function(object) {
  if (inherits(object, "RangedRaggedAssay")) {
    if (is.null(names(object))) {
      msg <- paste("names in", class(object), "are NULL")
      return(msg)
    } else {
      NULL
    }
  } else {
    NULL
  }
}

### ==============================================
### Elist class
### ----------------------------------------------

#' A container for multi-experiment data
#' 
#' The \code{Elist} class is a container that builds on 
#' the \code{\link[S4Vectors]{SimpleList-class}} with additional 
#' checks for consistency in experiment names and length.
#' It contains a \code{SimpleList} of experiments with sample identifiers.
#' One element present per experiment performed.  
#' 
#' Convert from \code{\link{SimpleList}} or \code{list}
#' to the multi-experiment data container
#'
#' @example inst/scripts/Elist-Ex.R
#'
#' @exportClass Elist
#' @aliases Elist
.Elist <- setClass("Elist", contains = "SimpleList")

### - - - - - - - - - - - - - - - - - - - - - - - -
### Builder
###

setGeneric("Elist", function(x) standardGeneric("Elist"))

#' @param x A \code{list} object
#' @return An \code{\linkS4class{Elist}} class object
#' @exportMethod Elist
#' @describeIn Elist Create an \link{Elist} object from an "ANY" class object, 
#' mainly \code{list}
setMethod("Elist", "ANY", function(x) {
  .Elist(S4Vectors::SimpleList(x))
})
#' @describeIn Elist Create an empty Elist for signature "missing"
setMethod("Elist", "missing", function(x) {
  .Elist(S4Vectors::SimpleList(list()))
})

### - - - - - - - - - - - - - - - - - - - - - - - -
### Validity 
###

.getMethErr2 <- function(object) {
  obj_cl <- class(object)
  supportedMethods <- c("colnames", "rownames", "[", "assay")
  methErr <- which(!sapply(supportedMethods, function(x) {
    .hasMethods(object, x)
  }))
  if (any(methErr)) {
    unsupported <- names(methErr)
    msg <- paste0("class '", obj_cl,
                  "' does not have method(s): ",
                  paste(unsupported, collapse = ", "))
    return(msg)
  }
  NULL
}

.checkMethodsTable <- function(object) {
  errors <- character()
  for (i in seq_along(object)) {
    coll_err <- .getMethErr2(object[[i]])
    if (!is.null(coll_err)) {
      errors <- c(errors, paste0("Element [", i, "] of ", coll_err))
    }
  }
  if (length(errors) == 0L) {
    NULL
  } else {
    errors
  }
}

.checkElistNames <- function(object) {
  errors <- character()
  for (i in seq_along(object)) {
    name_err <- .getNameErr(object[[i]])
    if (!is.null(name_err)) {
      errors <- c(errors, paste0("[", i, "] Element", name_err))
    }
  }
  if (any(duplicated(names(object)))) {
    msg <- "Non-unique names provided"
    errors <- c(errors, msg)
  }
  if (length(errors) == 0L) {
    NULL
  } else {
    errors
  }
}

.checkElistDims <- function(object) {
  emptyRows <- (vapply(object, nrow, integer(1)) == 0L)
  emptyCols <- (vapply(object, ncol, integer(1)) == 0L)
  newmat <- rbind(emptyRows, emptyCols)
  emptyDims <- apply(newmat, 2, any)
  if (any(emptyDims)) {
    warning("Elist elements",
            sprintf(" '%s' ", names(which(emptyDims))),
            "have empty dimensions")
  }
}

.validElist <- function(object) {
  if (length(object) != 0L) {
    c(.checkMethodsTable(object),
    .checkElistNames(object))
  }
}

## Make sure Elist is valid before checking all of the sample names

S4Vectors::setValidity2("Elist", .validElist)

#' @describeIn Elist Show method for \code{\linkS4class{Elist}} class
#' @param object An \code{\linkS4class{Elist}} class object
setMethod("show", "Elist", function(object) {
  o_class <- class(object)
  elem_cl <- vapply(object, class, character(1))
  o_len <- length(object)
  o_names <- names(object)
  sampdim <- vapply(object, FUN = function(obj) {
    ncol(obj)
  }, FUN.VALUE = integer(1))
  featdim <- vapply(object, FUN = function(obj) {
    nrow(obj)
  }, FUN.VALUE = integer(1))
  cat(sprintf('"%s"', o_class),
      "class object of length",
      paste0(o_len, ':'),
      sprintf('\n [%i] %s: "%s" - %s rows, %s columns',
              seq(o_len), o_names, elem_cl, featdim, sampdim), "\n")
})
