#' Find the optimal arguments fir each diagnostic
#'
#' @param object an object of class testargs
#' @param optimality_criterion a function (or list of functions) that defines the optimality criterion for each diagnostic. Should return a single index
#' @export
optimal_arguments <- function(object, optimality_criterion = which.min) {

  if(!is(object, "testargs"))
    stop("object should be of class testargs")

  if (is.list(optimality_criterion)) {

    if(length(optimality_criterion) != length(object@diagnostic_names))
      stop("If using a list of optimality criteria, please provide one function for each diagnostic (accessed with object@diagnostic_names).")

    if(is.null(names(optimality_criterion))) {
      optimal_idx <- sapply(1:length(diagnostic_names),
                            function(i) {
                              x <- object@diagnostics_df[, object@diagnostic_names[i], drop = T]
                              optimality_criterion[[i]](x)
                            })
    } else {
      if (!all(names(optimality_criterion) %in% object@diagnostic_names))
        stop("If optimality_criterion is a named list, it should have the same names as object@diagnostic_names")
      optimal_idx <- sapply(object@diagnostic_names,
                            function(i) {
                              x <- object@diagnostics_df[, i, drop = T]
                              optimality_criterion[[i]](x)
                            })
    }

  } else {
    optimal_idx <- sapply(diagnostics_df[, object@diagnostic_names, drop = F],
                          function(x) optimality_criterion(x))
  }

  names(optimal_idx) <- diagnostic_names
  out <- cbind(which_diagnostic_optimal = names(optimal_idx),
               object@diagnostics_df[optimal_idx, ])
  rownames(out) <- NULL

  return(out)
}