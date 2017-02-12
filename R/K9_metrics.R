#' Get List Of Active Metrics
#'
#' Get the list of actively reporting metrics from a given time until now.
#'
#' @param from seconds since the unix epoch
#' @export
k9_list_metrics <- function(from = NULL) {

  from <- to_epochtime(from)

  result <- k9_request(verb = "GET",
                       path = "/api/v1/metrics",
                       query = list(
                         from = from
                       ))

  purrr::flatten_chr(result$metrics)
}

#' Query Time Series Points
#'
#' This end point allows you to query for metrics from any time period.
#'
#' @param query query string
#' @param from seconds since the unix epoch
#' @param to seconds since the unix epoch
#'
#' @seealso \url{http://docs.datadoghq.com/api/?lang=console#metrics}, \url{http://docs.datadoghq.com/graphing/}
#'
#' @export
k9_get_metrics <- function(query, from = NULL, to = NULL) {
  to <- to_epochtime(to)
  if(is.null(from)) {
    from <- to - 3600
  } else {
    from <- to_epochtime(from)
  }

  result <- k9_request(verb = "GET",
                       path = "/api/v1/query",
                       query = list(
                         from  = from,
                         to    = to,
                         query = query
                       ))

  map_df(result$series, k9_flatten_series)
}

# map_int(x, length)
# #>       metric  query_index   attributes display_name         unit    pointlist          end     interval        start       length
# #>            1            1            0            1            2           31            1            1            1            1
# #>         aggr        scope   expression
# #>            0            1            1
k9_flatten_series <- function(x) {
  x_trans <- purrr::transpose(x$pointlist)

  timestamp_epoch <- purrr::flatten_dbl(x_trans[[1]]) / 1000
  timestamp <- anytime::anytime(timestamp_epoch)

  value <- purrr::flatten_dbl(x_trans[[2]])

  tibble::data_frame(
    timestamp    = timestamp,
    value        = value,
    metric       = x$metric,
    display_name = x$display_name,
    query_index  = x$query_index,
    interval     = x$interval,
    scope        = x$scope,
    expression   = x$expression
  )
}