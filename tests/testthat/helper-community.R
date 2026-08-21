# The arabinoxylan degradation chain, distributed across four genomes. The
# fixture is section 10 of inst/doc/proposal-quantitative-traits.md and the
# chain it exercises is curated, not invented:
#
#   arabinoxylan_debranching --XYLAN--> xylan_degradation
#   xylan_degradation --XYLOSE_EX--> xylose_uptake_abc
#   xylose_uptake_abc --XYLOSE_IN--> xylose_degradation_isomerase
#
# Marker sets were chosen so that each genome completes exactly the intended
# capabilities. That matters here: several CAZy families evidence both
# debranching and backbone cleavage, so a careless fixture would silently give
# genome A two capabilities and destroy every expected provider count.

arabinoxylan_markers <- list(
  # Alpha-glucuronidase alone completes debranching and nothing else.
  debrancher = "KO:K01209",
  # Endoxylanase plus beta-xylosidase, neither of which evidences debranching.
  backbone = c("CAZY:GH11", "CAZY:GH39"),
  # ABC transporter plus isomerase and xylulokinase: uptake and catabolism.
  consumer = c("KO:K10543", "KO:K10544", "KO:K10545", "KO:K01805", "KO:K00854")
)

namespaced_annotations <- function(markers) {
  data.frame(
    gene_id = paste0("gene_", seq_along(markers)),
    namespace = sub(":.*", "", markers),
    accession = sub(".*:", "", markers),
    stringsAsFactors = FALSE
  )
}

arabinoxylan_genome <- function(role) {
  evaluate_gifts(namespaced_annotations(arabinoxylan_markers[[role]]))
}

# The same fixture as one multi-genome annotation table, which is what
# evaluate_gifts_community() takes. Gene identifiers carry the role so that a
# genome mixed into another would be visible in the evidence.
arabinoxylan_table <- function(roles = names(arabinoxylan_markers)) {
  do.call(rbind, lapply(roles, function(role) {
    markers <- arabinoxylan_markers[[role]]
    data.frame(
      genome_id = role,
      gene_id = paste0(role, "_", seq_along(markers)),
      namespace = sub(":.*", "", markers),
      accession = sub(".*:", "", markers),
      stringsAsFactors = FALSE
    )
  }))
}

arabinoxylan_community <- function(abundance = NULL) {
  consumer <- arabinoxylan_genome("consumer")
  gifter_community(
    A = arabinoxylan_genome("debrancher"),
    B = arabinoxylan_genome("backbone"),
    C = consumer,
    D = consumer,
    abundance = abundance
  )
}

arabinoxylan_universe <- function() {
  gift_universe(label = "all curated GIFTs")
}
