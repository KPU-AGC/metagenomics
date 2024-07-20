#' @title Alpha Rarefaction Analysis from QIIME2
#' @description This script is intended for taking alpha rarefaction data from QIIME2 and identifying stabilization points.

# 1. Loading necessary libraries
#' The following libraries are loaded for data manipulation and analysis.
library(ggplot2)
library(tidyr)
library(dplyr)
library(readr)

library(pracma)
library(numDeriv)

#TODO: I probably need to adjust the loaded libraries--is this minimally sufficient? I can't remember.

metadata_df <- read.csv("meta.csv")

observed_features_df <- read.csv("observed_features.csv")
long_data <- observed_features_df %>%
  pivot_longer(
    cols = -sample.id,
    names_to = c("depth", "iteration"),
    names_pattern = "depth.(\\d+)_iter.(\\d+)",
    values_to = "value"
  ) %>%
  mutate(depth = as.numeric(depth), iteration = as.numeric(iteration))

long_data <- long_data %>%
  left_join(metadata_df, by="sample.id")

threshold <- 0.005
avg_df <- long_data %>%
  group_by(sample.id, depth) %>%
  summarise(avg_value = mean(value), .groups = 'drop') %>%
  filter(!is.na(avg_value) & !is.na(depth) & depth > 0)
results <- avg_df %>%
  group_by(sample.id) %>%
  do({

    # fit model
    log_model <- lm(avg_value ~ log(depth), data = .)
    
    # predict values
    predicted <- predict(log_model, newdata = data.frame(depth = .$depth))
    
    # compute derivative of model
    coefficients <- coef(log_model)
    derivative <- coefficients["log(depth)"] / .$depth
    
    # find stabilization point (where derivative passes threshold)
    threshold_indices <- which(abs(derivative) <= threshold)
    threshold_point <- if(length(threshold_indices) > 0) .$depth[threshold_indices[1]] else NA
    
    # cxombine results 
    data.frame(depth = .$depth, avg_value = .$avg_value, predicted = predicted, derivative = derivative, threshold_point = threshold_point)
  })
results <- results %>%
  left_join(metadata_df, by="sample.id")

alpha_rarefaction_plot <- ggplot(long_data, aes(x=depth, y=value, group=as.factor(sample.id), color=as.factor(affected.alleles))) +
  geom_smooth(method="glm", formula = y ~ log(x), linewidth=0.5) +
  geom_vline(xintercept=unique(results$threshold_point, na.rm=T) * 2, linetype="dashed", color="red", linewidth=.5) +
  labs(
    title="Fitted models of alpha rarefaction",
    y="Observed alleles",
    x="Sequencing depth",
    color="# alleles affected"
  ) +
  scale_y_continuous(expand=c(0,0), limits=c(0,100))
alpha_rarefaction_plot

dy_dx_alpha_rarefaction_plot <- ggplot(results, aes(x=depth, y=derivative, group=as.factor(sample.id), color=as.factor(affected.alleles))) +
  geom_line() +
  geom_vline(xintercept=unique(results$threshold_point, na.rm=T) * 2, linetype="dashed", color="red", linewidth=.5) +
  labs(
    title="Alpha rarefaction stabilization point (dy/dx < 0.005)",
    y="dy/dx fitted model",
    x="Sequencing depth",
    color="# alleles affected"
  ) +
  scale_y_continuous(expand=c(0,0))
dy_dx_alpha_rarefaction_plot


ggarrange(alpha_rarefaction_plot, dy_dx_alpha_rarefaction_plot, ncol = 1, nrow = 2, common.legend = TRUE, align = "hv")


count_passing_samples <- function(data, column, thresholds) {
  result <- sapply(thresholds, function(threshold) {
    sum(data[[column]] >= threshold)
  })
  return(result)
}

passing_samples <- count_passing_samples(samples_df, "reads.stitched.mapped.n", sort(unique(results$threshold_point, na.rm=T) * 2))
