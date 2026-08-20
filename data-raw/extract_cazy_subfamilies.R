#!/usr/bin/env Rscript
# Derive a light CAZy subfamily -> EC table from the dbCAN-sub HMM library.
#
# The library itself is ~4.9 GB and is not redistributable at that size, but the
# only part gifter needs is the profile NAME line, which encodes the eCAMI
# cluster, its parent family, the official CAZy subfamilies present in the
# cluster, and the EC numbers its members carry, each with a member count:
#
#   NAME AA1_e33.hmm|AA1:85|AA1_1:697|CE4:1|1.10.3.2:77
#
# Step 1 (shell) streams the library and keeps only those lines:
#   curl -s -r <range> <dbCAN_sub.hmm URL> | grep -a "^NAME"
# Step 2 (this script) parses them into inst/../data-raw/reference.
#
# The EC association is co-occurrence within a cluster, not a per-sequence
# assignment, so the fraction column is what makes it usable as evidence: it
# says how dominant one EC is among the EC-annotated members of the cluster.

args <- commandArgs(trailingOnly = TRUE)
input <- if (length(args) >= 1) args[[1]] else "data-raw/reference/dbcan_sub_names.txt"
output <- if (length(args) >= 2) args[[2]] else "data-raw/reference/cazy-subfamily-ec.tsv"

lines <- readLines(input, warn = FALSE)
lines <- sub("^NAME\\s+", "", lines[grepl("^NAME", lines)])
lines <- unique(lines)

is_ec <- function(label) lengths(strsplit(label, ".", fixed = TRUE)) == 4L

rows <- lapply(lines, function(name) {
  parts <- strsplit(name, "|", fixed = TRUE)[[1]]
  cluster <- sub("\\.hmm$", "", parts[[1]])
  family <- sub("_e[0-9]+$", "", cluster)
  # Only tokens carrying an explicit member count are assignments; dbCAN's own
  # parser skips the rest, and so do we.
  rest <- parts[-1]
  rest <- rest[grepl(":", rest, fixed = TRUE)]
  if (!length(rest)) return(NULL)

  label <- sub(":.*$", "", rest)
  count <- suppressWarnings(as.numeric(sub("^[^:]*:", "", rest)))
  keep <- !is.na(count)
  label <- label[keep]; count <- count[keep]
  if (!length(label)) return(NULL)

  ec <- is_ec(label)
  if (!any(ec)) return(NULL)

  # Official CAZy subfamilies present in the cluster, e.g. AA1_1.
  composition <- label[!ec]
  subfamilies <- composition[grepl("^[A-Z]+[0-9]+_[0-9]+$", composition)]

  total_ec <- sum(count[ec])
  data.frame(
    cazy_subfamily = cluster,
    family = family,
    ec = label[ec],
    ec_members = count[ec],
    ec_members_total = total_ec,
    ec_fraction = if (total_ec > 0) round(count[ec] / total_ec, 4) else NA_real_,
    cazy_official_subfamilies = if (length(subfamilies)) {
      paste(sort(unique(subfamilies)), collapse = ";")
    } else NA_character_,
    stringsAsFactors = FALSE
  )
})

table <- do.call(rbind, rows)
table <- table[order(table$family, table$cazy_subfamily, -table$ec_fraction, table$ec), ]
dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
utils::write.table(table, output, sep = "\t", quote = FALSE, row.names = FALSE, na = "")

cat("profiles parsed:      ", length(lines), "\n")
cat("clusters with an EC:  ", length(unique(table$cazy_subfamily)), "\n")
cat("subfamily/EC rows:    ", nrow(table), "\n")
cat("distinct EC numbers:  ", length(unique(table$ec)), "\n")
cat("written to:           ", output, "\n")
