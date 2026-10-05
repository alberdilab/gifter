# Compare the two R10 annotation inputs after both have been evaluated with the
# same gifter database. These are concordance measures, not accuracy estimates.

root <- "manuscript/analysis"
output <- file.path(root, "output", "r10-giftag")
drakkar <- file.path(root, "output", "r10-drakkar-current")
dir.create(output, recursive = TRUE, showWarnings = FALSE)

read_xz <- function(path) {
  con <- xzfile(path, "rt")
  on.exit(close(con), add = TRUE)
  read.delim(con, check.names = FALSE, stringsAsFactors = FALSE)
}
write_tsv <- function(x, path) {
  write.table(x, path, sep = "\t", quote = FALSE, row.names = FALSE, na = "")
}
write_xz <- function(x, path) {
  con <- xzfile(path, "wt", compression = 9)
  on.exit(close(con), add = TRUE)
  write_tsv(x, con)
}
get_audit <- function(path, key) {
  audit <- read.delim(path, stringsAsFactors = FALSE)
  value <- audit$value[audit$item == key]
  if (length(value) != 1L) stop("Missing input audit key: ", key)
  value
}

drakkar_audit <- file.path(drakkar, "r10-input-audit.tsv")
giftag_audit <- file.path(output, "r10-input-audit.tsv")
stopifnot(
  identical(get_audit(drakkar_audit, "gifter_sqlite_sha256"),
            get_audit(giftag_audit, "gifter_sqlite_sha256")),
  identical(get_audit(drakkar_audit, "published_bacterial_mags"), "822"),
  identical(get_audit(giftag_audit, "published_bacterial_mags"), "822"),
  identical(get_audit(drakkar_audit, "samples"), "388"),
  identical(get_audit(giftag_audit, "samples"), "388")
)

calls <- lapply(
  c(drakkar = drakkar, giftag = output),
  function(path) read_xz(file.path(path, "r10-supported-gift-calls.tsv.xz"))
)
key <- function(x) paste(x$genome_id, x$gift_id, sep = "\t")
stopifnot(!anyDuplicated(key(calls$drakkar)), !anyDuplicated(key(calls$giftag)))
keys <- lapply(calls, key)
both <- intersect(keys$drakkar, keys$giftag)
drakkar_only <- setdiff(keys$drakkar, keys$giftag)
giftag_only <- setdiff(keys$giftag, keys$drakkar)
all_keys <- union(keys$drakkar, keys$giftag)

gifts <- unique(rbind(
  calls$drakkar[c("gift_id", "gift_type")],
  calls$giftag[c("gift_id", "gift_type")]
))
stopifnot(!anyDuplicated(gifts$gift_id))
genomes <- sort(unique(c(calls$drakkar$genome_id, calls$giftag$genome_id)))
stopifnot(length(genomes) == 822L)

split_key <- function(keys) {
  if (!length(keys)) return(data.frame(genome_id = character(),
                                       gift_id = character()))
  fields <- strsplit(keys, "\t", fixed = TRUE)
  data.frame(
    genome_id = vapply(fields, `[[`, character(1), 1L),
    gift_id = vapply(fields, `[[`, character(1), 2L),
    stringsAsFactors = FALSE
  )
}
discordant <- rbind(
  transform(split_key(drakkar_only), caller = "drakkar_only"),
  transform(split_key(giftag_only), caller = "giftag_only")
)
discordant$gift_type <- gifts$gift_type[match(discordant$gift_id, gifts$gift_id)]
discordant <- discordant[order(discordant$gift_type, discordant$gift_id,
                               discordant$genome_id, discordant$caller), ]
write_xz(discordant, file.path(output, "r10-giftag-discordant-calls.tsv.xz"))

count <- function(keys, ids) {
  tabulate(match(split_key(keys)$genome_id, ids), length(ids))
}
per_genome <- data.frame(
  genome_id = genomes,
  drakkar_calls = count(keys$drakkar, genomes),
  giftag_calls = count(keys$giftag, genomes),
  shared_calls = count(both, genomes),
  drakkar_only = count(drakkar_only, genomes),
  giftag_only = count(giftag_only, genomes)
)
per_genome$union_calls <- per_genome$shared_calls +
  per_genome$drakkar_only + per_genome$giftag_only
per_genome$jaccard <- ifelse(
  per_genome$union_calls > 0,
  per_genome$shared_calls / per_genome$union_calls, NA_real_
)
write_tsv(per_genome, file.path(output, "r10-giftag-genome-concordance.tsv"))

group <- function(keys, type) {
  selected <- split_key(keys)
  selected$gift_type <- gifts$gift_type[match(selected$gift_id, gifts$gift_id)]
  sum(selected$gift_type == type)
}
types <- sort(unique(gifts$gift_type))
call_summary <- do.call(rbind, lapply(c("all", types), function(type) {
  take <- function(keys) if (type == "all") length(keys) else group(keys, type)
  shared <- take(both)
  d_only <- take(drakkar_only)
  g_only <- take(giftag_only)
  data.frame(
    gift_type = type,
    shared_calls = shared,
    drakkar_only = d_only,
    giftag_only = g_only,
    union_calls = shared + d_only + g_only,
    jaccard = if (shared + d_only + g_only) {
      shared / (shared + d_only + g_only)
    } else NA_real_,
    stringsAsFactors = FALSE
  )
}))
write_tsv(call_summary, file.path(output, "r10-giftag-call-concordance.tsv"))

traits <- lapply(
  c(drakkar = drakkar, giftag = output),
  function(path) read_xz(file.path(path, "r10-sample-traits.tsv.xz"))
)
metric_keys <- c("sample_id", "detection", "reference_frame", "metric_id")
for (caller in names(traits)) {
  stopifnot(!anyDuplicated(traits[[caller]][metric_keys]))
}
joined <- merge(
  traits$drakkar[c(metric_keys, "value", "numerator", "denominator")],
  traits$giftag[c(metric_keys, "value", "numerator", "denominator")],
  by = metric_keys, suffixes = c("_drakkar", "_giftag"), all = TRUE
)
stopifnot(nrow(joined) == nrow(traits$drakkar),
          nrow(joined) == nrow(traits$giftag))
joined$difference <- joined$value_giftag - joined$value_drakkar
groups <- interaction(
  joined[c("detection", "reference_frame", "metric_id")],
  drop = TRUE, lex.order = TRUE
)
metric_summary <- do.call(rbind, lapply(
  split(seq_len(nrow(joined)), groups),
  function(index) {
    row <- joined[index[[1L]],
                  c("detection", "reference_frame", "metric_id"), drop = FALSE]
    diff <- joined$difference[index]
    data.frame(
      row, samples = length(index),
      changed_samples = sum(!is.na(diff) & abs(diff) > 1e-10),
      mean_difference = mean(diff, na.rm = TRUE),
      median_absolute_difference = median(abs(diff), na.rm = TRUE),
      maximum_absolute_difference = max(abs(diff), na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }
))
rownames(metric_summary) <- NULL
write_tsv(metric_summary,
          file.path(output, "r10-giftag-sample-metric-concordance.tsv"))
cat("Compared ", length(all_keys), " union genome-GIFT calls and ",
    nrow(joined), " sample metrics on the same gifter database.\n", sep = "")
