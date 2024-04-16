library(dplyr)
library(tidyr)

read.otu_table <- function(input_path) {
  
  convert_to_taxonomic_format <- function(tax_string) {
    # Split the string by ";"
    parts <- strsplit(tax_string, ";")[[1]]
  
    # Define the taxonomic ranks in order
    taxonomic_ranks <- c("d", "p", "c", "o", "f", "g", "s")
  
    # Initialize a list with empty strings to hold each taxonomic level
    taxonomic_levels <- setNames(rep("", length(taxonomic_ranks)), taxonomic_ranks)
  
    # Loop through the parts and populate the taxonomic levels
    for (part in parts) {
        split_part <- strsplit(part, "__")[[1]]
        if (length(split_part) == 2) {
            key <- substr(split_part[1], 1, 1)
            value <- split_part[2]
            taxonomic_levels[[key]] <- value
        }
    }
  
    # Build the formatted string from the last non-empty taxonomic level
    last_non_empty <- max(which(taxonomic_levels != ""))
    last_taxon <- taxonomic_levels[last_non_empty]
    last_key <- names(taxonomic_levels)[last_non_empty]
  
    # Check if any of the taxonomic levels beyond 'd' are filled
    more_specific_levels_exist <- any(taxonomic_levels[names(taxonomic_levels) != "d"] != "")
  
    # Format the last taxon based on whether more specific levels exist
    if (last_taxon == "") {
        formatted_taxon <- sprintf("%s spp.", last_key)
    } else {
        if (more_specific_levels_exist) {
            formatted_taxon <- sprintf("%s spp.", last_taxon)
        } else {
            formatted_taxon <- last_taxon
        }
    }
  
    # Replace the last taxonomic level with the formatted taxon
    taxonomic_levels[last_non_empty] <- formatted_taxon
  
    # Return the full taxonomy up to the last identified level
    full_taxonomy <- taxonomic_levels[1:last_non_empty]
    return(full_taxonomy)
}
    
  wide_df <- read.csv(input_path, header=F)
  taxonomy_names <- unlist(wide_df[1,], use.names = F)[grepl("__", unlist(wide_df[1,], use.names = F))]
  
  
  wide_df <- read.csv(input_path)
  taxonomy_columns <- colnames(wide_df)[grepl("__", colnames(wide_df))]
  long_df <- wide_df %>%
    pivot_longer(
      cols = taxonomy_columns,
      names_to = "raw_taxonomy",
      values_to = "counts"
    )

  long_df$raw_taxonomy <- gsub("\\.(p__|c__|o__|f__|g__|s__|__)", ";\\1", long_df$raw_taxonomy)
  
  long_df$parsed_taxonomy <- lapply(long_df$raw_taxonomy, convert_to_taxonomic_format)
  return(long_df)
}

ggplot.stacked_taxonomy <- function(input_df, x = "index", top_n = 10, pattern="p; s") {
  
  create_taxonomy_str <- function(tax_list, pattern) {
    keys <- strsplit(pattern, ";")[[1]]
    keys <- trimws(keys)
    
    values <- sapply(keys, function(k) {
      if (k %in% names(tax_list)) {
        tax_list[[k]]
      } else {NA}
    }, USE.NAMES = FALSE)
    
    paste0(values, collapse = "; ")
  }
  
  input_df <- input_df %>%
    mutate(taxonomy_str = sapply(parsed_taxonomy, create_taxonomy_str, pattern))
  
  # Summarizing total count per species and selecting top species
  species_totals <- aggregate(counts ~ taxonomy_str, data = input_df, FUN = sum)
  top_species <- head(species_totals[order(-species_totals$count), "taxonomy_str"], top_n)
  
  # Collapsing all other species into 'Other'
  input_df$taxonomy_str <- ifelse(input_df$taxonomy_str %in% top_species, as.character(input_df$taxonomy_str), 'Other')
  
  # Reordering species to make 'Other' the last factor level
  input_df$taxonomy_str <- factor(input_df$taxonomy_str, levels = c(setdiff(unique(input_df$taxonomy_str), 'Other'), 'Other'))
  
  # Defining color palette
  palette_colors <- c("grey80", brewer.pal(7, "Dark2"))
  if(length(unique(input_df$taxonomy_str)) > length(palette_colors)) {
    extra_colors_needed <- length(unique(input_df$taxonomy_str)) - length(palette_colors)
    palette_colors <- c(palette_colors, brewer.pal(extra_colors_needed, "Set3"))
  }
  
  # Generating the plot
  output_plot <- ggplot(input_df, aes_string(fill = "taxonomy_str", y = "counts", x = x, order = "-as.numeric(taxonomy_str)")) + 
    geom_bar(position = "fill", stat = "identity") +
    scale_fill_manual(values = palette_colors) +
    guides(fill = guide_legend(reverse = FALSE)) + 
    scale_y_continuous(expand = c(0, 0), labels = scales::percent) +
    theme_light() +
    theme(
      panel.grid.major.x = element_blank(),
      panel.grid.minor.x = element_blank()
    ) +
    labs(x = "Sample", y = "Relative abundance (%)", fill = "Species")
  return(output_plot)
}

long_df <- read.otu_table("C:/Users/erick/Downloads/level-7.csv")

ggplot.stacked_taxonomy(long_df, x="site", top_n = 15, pattern = "d") +
  facet_wrap(~collection_date, scale="free_x")
