#' Simulate Time Series Data for ZI-INAR(1) or H-INAR(1) Models
#'
#' This function simulates time series data for Zero-Inflated INAR(1)
#' (ZI-INAR(1)) or Hurdle INAR(1) (H-INAR(1)) models, using either Poisson
#' or Negative Binomial distributions.
#'
#' @param n Integer specifying the number of observations to simulate.
#' @param alpha Numeric value between 0 and 1 representing the
#' autoregressive parameter.
#' @param rho Numeric value between 0 and 1 representing the zero-inflation
#' or hurdle parameter.
#' @param lambda Numeric value (> 0) representing the location parameter (mean)
#' for Poisson, or the location parameter for NB and GP distributions.
#' @param disp Numeric value representing the dispersion parameter.
#' \itemize{
#'   \item For \code{"nb"}: Must be positive (> 0).
#'   \item For \code{"gp"}: Must be strictly between 0 and 1 (0 < disp < 1).
#'   \item For \code{"poi"}: Ignored.
#' }
#' @param mod_type Character string indicating the model type ("zi" or "h").
#' @param distri Character string specifying the distribution. Options are:
#' \itemize{
#'   \item \code{"poi"} for Poisson
#'   \item \code{"nb"} for Negative Binomial
#'   \item \code{"gp"} for Generalized Poisson (Only \code{mod_type="zi"} supported)
#' }
#'
#'
#' @return A numeric vector containing the simulated time series data.
#'
#' @references
#' Part of the implementation of this function was adapted from the
#' \strong{ZINAR1} package.
#' The \strong{ZINAR1} package simulates first-order integer-valued
#' autoregressive processes
#' with zero-inflated innovations (ZINAR(1)) and estimates its parameters under
#' a frequentist approach.
#'
#' For more information about the ZINAR1 package, please refer to:
#'
#' Aldo M. Garay, João Vitor Ribeiro (2022).
#' \emph{ZINAR1: Simulates ZINAR(1) Model and Estimates Its Parameters
#' Under Frequentist Approach}.
#' R package version 0.1.0. Available at:
#' \url{https://CRAN.R-project.org/package=ZINAR1}.
#'
#' Garay, A. M., Ribeiro, J. V. (2021). First-Order Integer Valued AR Processes
#' with Zero-Inflated Innovations.
#' In: \emph{Nonstationary Systems: Theory and Applications}, Springer.
#' DOI: \doi{10.1007/978-3-030-82110-4_2}.
#'
#' We acknowledge the original authors, Aldo M. Garay and João Vitor Ribeiro,
#' for their contributions.
#'
#' @examples
#' # Simulate 50 observations from a Zero-Inflated Poisson INAR(1) model
#' y_data <- data_simu(n = 50, alpha = 0.5, rho = 0.3, lambda = 5,
#'                     mod_type = "zi", distri = "poi")
#' head(y_data)
#'
#' @importFrom VGAM rzipois rzinegbin
#' @importFrom actuar rztpois rztnbinom
#' @importFrom stats runif rbinom
#' @export
data_simu <- function(n, alpha, rho, lambda, disp = NULL, mod_type, distri) {

  if (!is.numeric(n) || length(n) != 1 || n <= 0 || n != as.integer(n)) {
    stop("The parameter 'n' must be a positive integer.")
  }
  if (!is.numeric(alpha) || length(alpha) != 1 || alpha <= 0 || alpha >= 1) {
    stop("The parameter 'alpha' must be a numeric value strictly between 0 and 1.")
  }
  if (!is.numeric(rho) || length(rho) != 1 || rho < 0 || rho > 1) {
    stop("The parameter 'rho' must be a numeric value between 0 and 1.")
  }
  if (!(mod_type %in% c("zi", "h"))) {
    stop("The parameter 'mod_type' must be either 'zi' (zero-inflated) or 'h' (hurdle).")
  }
  if (!(distri %in% c("poi", "nb", "gp"))) {
    stop("The parameter 'distri' must be one of: 'poi', 'nb', 'gp'.")
  }

  if (mod_type == "h" && distri == "gp") {
    stop(paste0("Hurdle models ('h') are not implemented for distribution '", distri,
                "'. Only Zero-Inflated ('zi') models are supported for GP."))
  }

  if (missing(lambda) || !is.numeric(lambda) || length(lambda) != 1 || lambda <= 0) {
    stop("The parameter 'lambda' must be a positive numeric value.")
  }

  if (distri %in% c("nb", "gp")) {
    if (is.null(disp) || !is.numeric(disp) || length(disp) != 1) {
      stop(paste0("For distribution '", distri, "', the parameter 'disp' must be a numeric value."))
    }

    if (distri == "gp") {
      if (disp <= 0 || disp >= 1) {
        stop("For Generalized Poisson ('gp'), 'disp' must be strictly between 0 and 1.")
      }
    } else {
      if (disp <= 0) {
        stop(paste0("For distribution '", distri, "', the parameter 'disp' must be positive."))
      }
    }
  }

  n_neg = 100
  y = s = vector()

  if (mod_type == "zi" && distri == "poi") {
    muy = lambda * (1 - rho) / (1 - alpha)
    y[1] = round(muy)
    w = VGAM::rzipois(n + n_neg, lambda, rho)
  }

  if (mod_type == "zi" && distri == "nb") {
    muy = lambda * (1 - rho) / (1 - alpha)
    y[1] = round(muy)
    w = VGAM::rzinegbin(n + n_neg, pstr0 = rho, munb = lambda,
                        size = disp)
  }

  if (mod_type == "h" && distri == "poi") {
    muy = lambda * (1 - rho) / ((1 - alpha) * (1 - exp(-lambda)))
    y[1] = round(muy)
    w <- runif(n + n_neg)
    w[w < rho] <- 0
    w[w > 0] <- actuar::rztpois(n + n_neg - length(w[w < rho]), lambda)
  }

  if (mod_type == "h" && distri == "nb") {
    muy = lambda * (1 - rho) /
      ((1 - alpha) * (1 - (disp / (lambda + disp))^disp))
    y[1] = round(muy)
    w <- runif(n + n_neg)
    w[w < rho] <- 0
    w[w > 0] <- actuar::rztnbinom(n + n_neg - length(w[w < rho]), disp,
                                  1 - lambda / (lambda + disp))
  }

  if (mod_type == "zi" && distri == "gp") {
    muy = (1 - rho) * lambda / ((1 - alpha) * (1 - disp))
    y[1] = round(muy)
    w <- runif(n + n_neg)
    w[w < rho] <- 0
    w[w > 0] <- rgenpois(n + n_neg - length(w[w < rho]), lambda, disp)
  }

  for (i in 2:(n + n_neg)) {
    s[i] = rbinom(1, y[i - 1], alpha)
    y[i] = s[i] + w[i]
  }

  y = y[-(1:n_neg)]

  return(y)
}
