testarguments
=========

An `R` package for testing and visualising the performance of a prediction algorithm with different combinations of function arguments. These functions are useful for optimising the predictive performance of a model when it has a several arguments to specify (e.g., the number of basis functions, the number of resolutions, different priors, link functions, etc.). This is particularly true if one suspects an *interaction* between argument levels. This package can help to select arguments in a fair and systematic fashion in the context of a comparative study.
		
		
Installation tips
-------

To install the package, simply type the following command in `R`:

```r
devtools::install_github("MattSainsbury-Dale/testarguments")
```


Example
------------

We demonstrate use of `testarguments` by predicting with the package `FRK`. First, load the required packages.

```r
library("testarguments")
library("FRK")
library("sp")
library("pROC") # AUC score
```

Now create training and testing data.

```r
n <- 5000                                                  # sample size
RNGversion("3.6.0"); set.seed(1)
data("MODIS_cloud_df") # MODIS dataframe stored in FRK (FRKTMB branch)
train_id <- sample(1:nrow(MODIS_cloud_df), n, replace = FALSE)
df_train <- MODIS_cloud_df[train_id, ]                     # training set
df_test  <- MODIS_cloud_df[-train_id, ]                    # testing set
```

Define a wrapper function which uses `df_train` to predict over `df_test`. This will be passed into `test_arguments()`. In this example, we wish to test values of `link` and `nres`, so we include these as arguments in the wrapper function. 

```r
fun <- function(df_train, df_test, link, nres) {
  
  ## Convert dataframes to Spatial* objects (as required by FRK)
  coordinates(df_train) <- ~ x + y
  coordinates(df_test) <- ~ x + y

  ## BAUs (just use a grid over the spatial domain of interest)
  BAUs    <- SpatialPixelsDataFrame(points = expand.grid(x = 1:225, y = 1:150),
                                    data = expand.grid(x = 1:225, y = 1:150))

  ## Fit using df_train
  df_train$k_Z <- 1 # size parameter of the binomial distribution
  S <- FRK(f = z ~ 1, data = list(df_train), BAUs = BAUs, response = "binomial",
           link = link, nres = nres)

  ## Predict using df_test
  pred <- predict(S, newdata = df_test, type = "response")

  ## Returned object must be a matrix-like object with named columns
  return(pred$newdata@data)
}
```

Define diagnostic function: This should return a named vector.

```r
diagnostic_fun <- function(df) {
  with(df, c(
    Brier = mean((z - p_Z)^2),
    AUC = as.numeric(pROC::auc(z, p_Z))
  ))
}
```

Compute the user-defined diagnostics over a range of arguments using `test_arguments()`. Here, we test the prediction algorithm with 1, 2, or 3 resolutions of basis functions, and using the logit or probit link function.

```r
testargs_object <- test_arguments(
  fun, df_train, df_test, diagnostic_fun,
  arguments = list(link = c("logit", "probit"), nres = 1:3)
)
```

Visualise the performance across all combinations of the supplied arguments using `plot_diagnostics()`.

```r
plot_diagnostics(testargs_object)
```


![Predictive performance for all combinations of nres and link](/img/nres_link.png?raw=true)


Using various aesthetics, `plot_diagnostics()` can visualise the performance of all combinations of up to 4 different arguments simultaneously. If we decide that the link function is not relevant, we can focus on only the number of resolutions by specifying `focused_args = "nres"`. By default, this averages out the arguments which are not of interest. 

```r
plot_diagnostics(testargs_object, focused_args = "nres")
```

![Focusing on nres: levels of link have been averaged out](/img/nres.png?raw=true)



