###############################################################################
##  Alpha-Rarefaction Plateau Detection  – modular version                   ##
##  • Fits an SSasymp model per sample (falls back to raw-average line).     ##
##  • Green = plateau, Red = needs more reads.                               ##
##  • End-labels coloured by status, failing samples printed at the end.     ##
###############################################################################

suppressPackageStartupMessages({
  library(tidyverse)    # ggplot2, dplyr, tidyr, readr, purrr
  library(ggrepel)
})

# ── global parameters --------------------------------------------------------
params <- list(
  rare_path   = "",
  meta_path   = NULL,       # optional metadata
  thresh_abs  = 0.005,      # absolute |dy/dx| cutoff
  thresh_prop = 0.00001     # proportional cutoff (× Asymptote)
)

# ── 1.  I/O & tidying --------------------------------------------------------
rename_id <- function(df) {
  if (!"sample.id" %in% names(df)) names(df)[1] <- "sample.id"
  df
}

load_rarefaction <- function(path) {
  read_csv(path, show_col_types = FALSE) |>
    rename_id()
}

tidy_long <- function(rare_df) {
  rare_df %>%
    pivot_longer(
      cols       = -sample.id,
      names_to   = c("depth", "iteration"),
      names_pattern = "depth.(\\d+)_iter.(\\d+)",
      values_to  = "value"
    ) %>%
    mutate(depth = as.numeric(depth),
           iteration = as.numeric(iteration))
}

average_by_depth <- function(long_df) {
  long_df |>
    group_by(sample.id, depth) |>
    summarise(y = mean(value), .groups = "drop") |>
    filter(depth > 0, !is.na(y))
}

# ── 2.  Model fitting & plateau flag ----------------------------------------
fit_sample <- function(df, abs_cut, prop_cut) {
  res <- tibble(sample.id = df$sample.id[1],
                Asym = NA, R0 = NA, lrc = NA,
                stab_depth = NA, plateau_reached = FALSE,
                fit_type = "avg")        # fallback tag
  
  if (n_distinct(df$depth) < 3) return(res)
  
  mod <- tryCatch(
    nls(y ~ SSasymp(depth, Asym, R0, lrc), data = df),
    error = function(e) NULL
  )
  if (is.null(mod)) return(res)
  
  co   <- coef(mod)
  rate <- exp(co["lrc"])
  thr  <- max(abs_cut, prop_cut * co["Asym"])
  x_star <- -log(thr / ((co["Asym"] - co["R0"]) * rate)) / rate
  stab   <- min(df$depth[df$depth >= x_star], na.rm = TRUE)
  plateau <- max(df$depth) >= stab
  
  res$Asym <- co["Asym"]; res$R0 <- co["R0"]; res$lrc <- co["lrc"]
  res$stab_depth <- stab; res$plateau_reached <- plateau
  res$fit_type   <- "asymp"
  res
}

fit_all <- function(avg_df, abs_cut, prop_cut) {
  avg_df |>
    group_by(sample.id) |>
    group_modify(~fit_sample(.x, abs_cut, prop_cut)) |>
    ungroup()
}

# ── 3.  Prediction curves & labels ------------------------------------------
predict_curves <- function(fit_tbl, avg_df) {
  # SSasymp curves for successful fits
  pred_asymp <- fit_tbl |>
    filter(fit_type == "asymp") |>
    mutate(curve = pmap(list(Asym, R0, lrc, sample.id), \(A, R, k, id) {
      d <- seq(0, max(avg_df$depth[avg_df$sample.id == id]), length.out = 200)
      tibble(depth = d, fitted = SSasymp(d, A, R, k))
    })) |>
    unnest(curve)
  
  # straight lines for failed fits
  pred_avg <- avg_df |>
    left_join(fit_tbl |> select(sample.id, plateau_reached, fit_type),
              by = "sample.id") |>
    filter(fit_type == "avg") |>
    rename(fitted = y)
  
  list(asymp = pred_asymp, avg = pred_avg)
}

curve_labels <- function(pred_asymp, pred_avg) {
  bind_rows(
    pred_asymp |> group_by(sample.id) |> slice_max(depth, n = 1),
    pred_avg   |> group_by(sample.id) |> slice_max(depth, n = 1)
  ) |> ungroup()
}

# ── 4.  Plotting -------------------------------------------------------------
plot_rarefaction <- function(long_flagged, curves, label_df) {
  cols <- c(`TRUE` = "forestgreen", `FALSE` = "firebrick")
  
  ggplot(long_flagged, aes(depth, value)) +
    geom_jitter(aes(colour = plateau_reached),
                alpha = .25, size = 1, width = 10) +
    
    geom_line(data = curves$asymp,
              aes(depth, fitted, group = sample.id,
                  colour = plateau_reached),
              linewidth = .8) +
    
    geom_line(data = curves$avg,
              aes(depth, fitted, group = sample.id,
                  colour = plateau_reached),
              linewidth = .8, linetype = "22") +
    
    geom_text_repel(data = label_df,
                    aes(depth, fitted, label = sample.id,
                        colour = plateau_reached),
                    size = 3,
                    min.segment.length = 0,
                    box.padding = .3,
                    point.padding = .2,
                    segment.color = "grey50",
                    max.overlaps = Inf,
                    show.legend = FALSE) +
    
    scale_colour_manual(values = cols, name = "Plateau reached") +
    labs(title = "Alpha-rarefaction per sample",
         subtitle = "Green = plateau • Red = rising  (dashed = fit failed)",
         x = "Sequencing depth", y = "Observed features") +
    theme_bw(base_size = 12)
}

# ── 5.  Reporting ------------------------------------------------------------
report_failing <- function(fit_tbl) {
  failing <- fit_tbl |> filter(!plateau_reached) |> pull(sample.id)
  cat("\nPlateau summary:\n")
  print(fit_tbl |> select(sample.id, stab_depth, plateau_reached, fit_type))
  cat("\nSamples requiring deeper sequencing:\n")
  if (length(failing)) {
    print(failing)
  } else {
    cat("None – all samples reached a plateau.\n")
  }
}

# ── 6.  Main -----------------------------------------------------------------
main <- function(p = params) {
  rare  <- load_rarefaction(p$rare_path)
  long  <- tidy_long(rare)
  avg   <- average_by_depth(long)
  fits  <- fit_all(avg, p$thresh_abs, p$thresh_prop)
  
  curves <- predict_curves(fits, avg)
  labels <- curve_labels(curves$asymp, curves$avg)
  long_flagged <- long |> left_join(fits |> select(sample.id, plateau_reached),
                                    by = "sample.id")
  
  print(plot_rarefaction(long_flagged, curves, labels))
  report_failing(fits)
}

# ── run ----------------------------------------------------------------------
main()
