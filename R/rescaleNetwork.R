#' Normalize coordinates to unit cube maintaining its geography.
#'
#' @template arg_network
#' @param method [\code{character(1)}]\cr
#'   Rescaling method which actually modifies the coordinates.
#'   Currently there are three methods available:
#'   \describe{
#'     \item{by.dimension}{Scaling is performed for each dimension independently.}
#'     \item{global}{Here we shift all the points toward the origin by the minimum of both
#'     x and y coordiantes and devide by the range of global maximim and minimum.}
#'     \item{global2}{Here wer shift - analogously to the \code{by.dimension} strategy -
#'     dimension wise and devide by the maximum of the ranges in x respectivly y direction.}
#'   }
#'   Default is \code{global2}, which leads to the most \dQuote{natural} rescaling.
#' @examples
#' \dontrun{
#' library(gridExtra)
#' x = generateClusteredNetwork(n.points = 100L, n.cluster = 4L, name = "Rescaling Demo")
#' # here we "stretch" the instance x direction
#' x$coordinates[, 1] = x$coordinates[, 1] * 10L
#' x$upper = x$upper * 10L
#' pls = list(
#'     autoplot(x) + ggtitle("Original"),
#'     autoplot(rescaleNetwork(x, method = "by.dimension")) + ggtitle("By dimension"),
#'     autoplot(rescaleNetwork(x, method = "global")) + ggtitle("Global"),
#'     autoplot(rescaleNetwork(x, method = "global2")) + ggtitle("Global2")
#' )
#' pls$nrow = 1L
#' do.call(grid.arrange, pls)
#' }
#' @return [\code{Network}]
#' @export
rescaleNetwork = function(x, method = "global2") {
  assertClass(x, "Network")
  if (hasDepots(x)) {
    stopf("Rescaling of networks with depots currently not supported.")
  }
  method.mapping = list(
    "by.dimension" = rescaleNetworkByDimension,
    "global" = rescaleNetworkGlobal,
    "global2" = rescaleNetworkGlobal2
    )
  assertChoice(method, choices = names(method.mapping))
  rescaleMethod = method.mapping[[method]]
  x$coordinates = rescaleMethod(x$coordinates)

    # rescaling is a normalization to [0,1]^dim
  x$lower = 0
  x$upper = 1
  return(x)
}

# Rescale by normalizing with global min/max values.
rescaleNetworkGlobal = function(x) {
  rg = range(x)
  (x - rg[1]) / (rg[2] - rg[1])
}

# Rescale by shifting dimension-wise and scaling with the maximal range
rescaleNetworkGlobal2 = function(x) {
  rgs = apply(x, 2, range)
  # we could transpose x first and transpose another time after rescaling,
  # but this is more efficient
  x[, 1] = (x[, 1] - rgs[1, 1])
  x[, 2] = (x[, 2] - rgs[1, 2])
  scale = max(rgs[2,] - rgs[1,])
  x / scale
}

# Rescale by normalizing dimension-wise with min/max values
rescaleNetworkByDimension = function(x) {
  min = apply(x, 2, min)
  max = apply(x, 2, max)
  t((t(x) - min) / (max - min))
}
