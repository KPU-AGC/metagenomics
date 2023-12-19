library(ggplot2)
library(dplyr)
library(forcats)
library(RColorBrewer)

counts_df <- read.csv("output.csv")

plot_taxonomy_stacked_bars <- function(input_df, top_n = 10) {
  ""
  ""
  top_species <- input_df %>%
    group_by(species) %>%
    summarise(total_count = sum(count)) %>%
    top_n(top_n, total_count) %>%
    pull(species)

  input_df$species <- ifelse(counts_df$species %in% top_species, as.character(input_df$species), 'Other')
  input_df$species <- fct_relevel(input_df$species, "Other")

  palette_colors <- c("grey80", brewer.pal(7,"Dark2"))

  if(length(unique(input_df$species)) > length(palette_colors)) {
    extra_colors_needed <- length(unique(input_df$species)) - length(palette_colors)
    palette_colors <- c(palette_colors, brewer.pal(extra_colors_needed, "Set3"))
  }

  output_plot <- ggplot(input_df, aes(fill=species, y=count, x=sample, order=-as.numeric(species))) + 
    geom_bar(position="fill", stat="identity") +
    scale_fill_manual(values = palette_colors) +
    guides(fill=guide_legend(reverse = F)) + 
    ylim(0, 1) + scale_y_continuous(expand = c(0, 0), labels = scales::percent) +
    theme_light() +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank()
      ) +
    labs(x = "Sample", y = "Relative abundance (%)", fill="Species")
  print(output_plot)
}

plot_taxonomy_stacked_bars(counts_df, top_n = 10)
