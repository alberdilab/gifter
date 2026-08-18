ko_annotations <- function(markers) {
  data.frame(
    gene_id = paste0("gene_", seq_along(markers)),
    namespace = "KO",
    accession = markers,
    stringsAsFactors = FALSE
  )
}

direct_purine_markers <- function(include_amp = FALSE) {
  markers <- c(
    "K00764", "K01945", "K00601", "K01952", "K01933",
    "K01587", "K01756", "K00602"
  )
  if (include_amp) markers <- c(markers, "K01939")
  markers
}

alternative_purine_markers <- function() {
  c(
    "K00764", "K01945", "K08289", "K01952", "K01933",
    "K01589", "K01588", "K01923", "K01756", "K06863", "K11176"
  )
}

multifunctional_pyrimidine_markers <- function() {
  c("K11540", "K00254", "K13421")
}

complex_pyrimidine_markers <- function() {
  c(
    "K01955", "K01956", "K00609", "K01465",
    "K00226", "K00762", "K01591"
  )
}
