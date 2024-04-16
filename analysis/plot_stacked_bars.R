library(dplyr)
library(tidyr)

#' read.abundance_table
#'
#' A function that reads the wide-format tabular (.csv?) output from QIIME2's
#' stacked barplot visualization and imports it to a more-workable dataframe 
#' that can be visualized using ggplot architecture.
#' 
#' @param input_path A string representation of the input path 
#'
#' @return Returns a long-format dataframe containing metadata from QIIME as
#' well as required 'index', 'raw_taxonomy', 'counts', and 'parsed taxonomy'.
#'
#' @examples
#' long_format_df <- read.abundance_table("/home/erick/Documents/abundance_table.csv")
read.abundance_table <- function(input_path) {
  
#' convert_to_taxonomic_format
#'
#' Function takes a raw taxonomy string--as formatted in QIIME2--and converts it
#' to a consistent named list for easier processing.
#'
#' @param tax_string A string with QIIME2 formatting--with ";" delimiting the
#' taxonomic group.
#'
#' @return Returns a named list.
#'
#' @examples
#' long_df$parsed_taxonomy <- lapply(long_df$raw_taxonomy, convert_to_taxonomic_format)
  convert_to_taxonomic_format <- function(tax_string) {
    
    # Domain, Phylum, Class, Order, Family, Genus, Species
    taxonomic_ranks <- c("d", "p", "c", "o", "f", "g", "s")

    # Split the string by ";"
    parts <- strsplit(tax_string, ";")[[1]]

    # Loop through the parts and populate the taxonomic levels
    taxonomic_levels <- setNames(rep("", length(taxonomic_ranks)), taxonomic_ranks)
    for (part in parts) {
        split_part <- strsplit(part, "__")[[1]]
        if (length(split_part) == 2) {
            key <- substr(split_part[1], 1, 1)
            value <- split_part[2]
            taxonomic_levels[[key]] <- value
        }
    }
    # handle the Unassigned case.
    if (taxonomic_levels["d"] == "") {
      taxonomic_levels[c("d", "p", "o", "f", "g", "s")] <- "Unassigned"
    }

    # Build the formatted string from the last non-empty taxonomic level
    last_non_empty <- max(which(taxonomic_levels != ""))
    last_taxon <- taxonomic_levels[last_non_empty]
    last_key <- names(taxonomic_levels)[last_non_empty]
    more_specific_levels_exist <- any(taxonomic_levels[names(taxonomic_levels) != "d"] != "")
    if (last_taxon == "") {
        formatted_taxon <- sprintf("%s spp.", last_key)
    } else {
        if (more_specific_levels_exist) {
            formatted_taxon <- sprintf("%s spp.", last_taxon)
        } else {
            formatted_taxon <- last_taxon
        }
    }
  
    taxonomic_levels[last_non_empty] <- formatted_taxon
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

#' ggplot.stacked_taxonomy
#'
#' A function that uses ggplot as a foundation for plotting the parsed abundance
#' table with some options for modularity.
#'  
#' @param input_df An input dataframe, should be the input from the other 
#' function (read.abundance_table).
#' @param x A string containing the name of the column/variable to use for the 
#' x-axis, defaults to 'index'.
#' @param top_n An int for how many of the top taxa to plot in the legend.
#' @param pattern A string for the taxonomy pattern to use for plotting.
#'
#' @return Returns a ggplot object that can be stacked with other 
#'
#' @examples
#' ggplot.stacked_taxonomy(long_df)
#' 
#' ggplot.stacked_taxonomy(long_df, x = "site", top_n = 15, pattern = "d; p") +
#'   facet_wrap(~collection_date, scale="free_x")
ggplot.stacked_taxonomy <- function(input_df, x = "index", top_n = 10, pattern="g; s") {
  
  #' create_taxonomy_str
  #'
  #' Function for collapsing entries depending on input string pattern.
  #' @param tax_list A named list from the input dataframe.
  #' @param pattern A string pattern in "d; p; c; o; f; g; s" format to parse.
  #'
  #' @return Returns a string representation of the entry's taxonomy based on
  #' the input pattern.
  #'
  #' @examples
  #' input_df <- input_df %>%
  #'   mutate(taxonomy_str = sapply(parsed_taxonomy, create_taxonomy_str, pattern))
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
    
  #' expand_taxonomy
  #'
  #' Function takes an input pattern from the parent function and expands it
  #' for the figure legend.
  #' @param text A string pattern in "d; p; c; o; f; g; s" format to parse.
  #'
  #' @return Returns a string of the expanded pattern.
  #'
  #' @examples
  #' labs(x = "Sample", y = "Relative abundance (%)", fill = paste0("Species (", expand_taxonomy(pattern), ")"))
  expand_taxonomy <- function(text) {
    replacements <- c(
      "d" = "Domain",
      "p" = "Phylum",
      "c" = "Class",
      "o" = "Order",
      "f" = "Family",
      "g" = "Genus",
      "s" = "Species"
    )
    
    for (key in names(replacements)) {
      # Using regex and ignore.case to handle both cases
      text <- gsub(paste0("\\b", key, "\\b"), replacements[key], text, ignore.case = TRUE)
    }
    return(text)
  }
  
  input_df <- input_df %>%
    mutate(taxonomy_str = sapply(parsed_taxonomy, create_taxonomy_str, pattern))
  
  # get total counts aggregated across all samples and get the top_n.
  species_totals <- aggregate(counts ~ taxonomy_str, data = input_df, FUN = sum)
  top_species <- head(species_totals[order(-species_totals$count), "taxonomy_str"], top_n)
  
  # collapse all other species not in top_n into 'Other'
  input_df$taxonomy_str <- ifelse(input_df$taxonomy_str %in% top_species, as.character(input_df$taxonomy_str), 'Other')
  
  # Reordering species to make 'Other' the last factor level
  input_df$taxonomy_str <- factor(input_df$taxonomy_str, levels = c(setdiff(unique(input_df$taxonomy_str), 'Other'), 'Other'))
  
  # Defining color palette
  palette_colors <- c("grey80", brewer.pal(7, "Dark2"))
  if(length(unique(input_df$taxonomy_str)) > length(palette_colors)) {
    extra_colors_needed <- length(unique(input_df$taxonomy_str)) - length(palette_colors)
    palette_colors <- c(palette_colors, brewer.pal(extra_colors_needed, "Set3"))
  }
  

  # ggplot elements
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
    labs(x = "Sample", y = "Relative abundance (%)", fill = paste0("Species (", expand_taxonomy(pattern), ")"))

  return(output_plot)
}





long_df <- read.abundance_table("C:/Users/erick/Downloads/level-7.csv")
ggplot.stacked_taxonomy(long_df, x = "site", top_n = 15, pattern = "d; p") +
  facet_wrap(~collection_date, scale="free_x")
