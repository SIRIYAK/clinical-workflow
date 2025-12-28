# ==============================================================================
# TLF (Tables, Listings, Figures) Utilities
# Script: tlf_utilities.R
# Purpose: Utility functions for generating regulatory-compliant TLF outputs
# ==============================================================================

library(dplyr)
library(tidyr)
library(gt)
library(flextable)
library(officer)

# ==============================================================================
# Table Generation Functions
# ==============================================================================

#' Create Regulatory Table with Standard Formatting
#' @param data Data frame for table
#' @param title Table title
#' @param footnotes Vector of footnotes
#' @param output_format "rtf", "docx", or "html"
#' @return Formatted table object
create_regulatory_table <- function(data, title, footnotes = NULL, output_format = "rtf") {
  
  # Create flextable
  ft <- flextable(data) %>%
    theme_booktabs() %>%
    fontsize(size = 9, part = "all") %>%
    font(fontname = "Times New Roman", part = "all") %>%
    align(align = "left", part = "header") %>%
    align(align = "left", j = 1, part = "body") %>%
    align(align = "center", j = 2:ncol(data), part = "body") %>%
    bold(part = "header") %>%
    border_remove() %>%
    hline_top(border = fp_border(width = 2), part = "header") %>%
    hline_bottom(border = fp_border(width = 2), part = "header") %>%
    hline_bottom(border = fp_border(width = 2), part = "body")
  
  # Add title
  ft <- add_header_lines(ft, values = title)
  ft <- bold(ft, i = 1, part = "header")
  
  # Add footnotes
  if (!is.null(footnotes)) {
    for (fn in footnotes) {
      ft <- add_footer_lines(ft, values = fn)
    }
    ft <- fontsize(ft, size = 8, part = "footer")
    ft <- italic(ft, part = "footer")
  }
  
  return(ft)
}

#' Export Table to RTF
#' @param table_obj Flextable object
#' @param filename Output filename
#' @param path Output directory path
export_table_rtf <- function(table_obj, filename, path = "outputs/tlf/tables") {
  output_file <- file.path(path, paste0(filename, ".rtf"))
  save_as_rtf(table_obj, path = output_file)
  cat(glue("✓ Table saved: {basename(output_file)}\n"))
}

#' Export Table to DOCX
#' @param table_obj Flextable object
#' @param filename Output filename
#' @param path Output directory path
export_table_docx <- function(table_obj, filename, path = "outputs/tlf/tables") {
  output_file <- file.path(path, paste0(filename, ".docx"))
  save_as_docx(table_obj, path = output_file)
  cat(glue("✓ Table saved: {basename(output_file)}\n"))
}

# ==============================================================================
# Statistical Summary Functions
# ==============================================================================

#' Calculate Summary Statistics for Continuous Variables
#' @param data Data frame
#' @param var Variable name
#' @param by_var Grouping variable (optional)
#' @return Summary statistics
summarize_continuous <- function(data, var, by_var = NULL) {
  
  if (is.null(by_var)) {
    summary <- data %>%
      summarise(
        N = sum(!is.na(!!sym(var))),
        Mean = mean(!!sym(var), na.rm = TRUE),
        SD = sd(!!sym(var), na.rm = TRUE),
        Median = median(!!sym(var), na.rm = TRUE),
        Min = min(!!sym(var), na.rm = TRUE),
        Max = max(!!sym(var), na.rm = TRUE)
      ) %>%
      mutate(
        `Mean (SD)` = sprintf("%.1f (%.2f)", Mean, SD),
        `Median (Min, Max)` = sprintf("%.1f (%.1f, %.1f)", Median, Min, Max)
      ) %>%
      select(N, `Mean (SD)`, `Median (Min, Max)`)
  } else {
    summary <- data %>%
      group_by(!!sym(by_var)) %>%
      summarise(
        N = sum(!is.na(!!sym(var))),
        Mean = mean(!!sym(var), na.rm = TRUE),
        SD = sd(!!sym(var), na.rm = TRUE),
        Median = median(!!sym(var), na.rm = TRUE),
        Min = min(!!sym(var), na.rm = TRUE),
        Max = max(!!sym(var), na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        `Mean (SD)` = sprintf("%.1f (%.2f)", Mean, SD),
        `Median (Min, Max)` = sprintf("%.1f (%.1f, %.1f)", Median, Min, Max)
      ) %>%
      select(!!sym(by_var), N, `Mean (SD)`, `Median (Min, Max)`)
  }
  
  return(summary)
}

#' Calculate Frequency and Percentage for Categorical Variables
#' @param data Data frame
#' @param var Variable name
#' @param by_var Grouping variable (optional)
#' @return Frequency table
summarize_categorical <- function(data, var, by_var = NULL) {
  
  if (is.null(by_var)) {
    freq_table <- data %>%
      count(!!sym(var)) %>%
      mutate(
        Total = sum(n),
        Percent = n / Total * 100,
        `n (%)` = sprintf("%d (%.1f%%)", n, Percent)
      ) %>%
      select(!!sym(var), `n (%)`)
  } else {
    freq_table <- data %>%
      group_by(!!sym(by_var), !!sym(var)) %>%
      summarise(n = n(), .groups = "drop") %>%
      group_by(!!sym(by_var)) %>%
      mutate(
        Total = sum(n),
        Percent = n / Total * 100,
        `n (%)` = sprintf("%d (%.1f%%)", n, Percent)
      ) %>%
      select(!!sym(by_var), !!sym(var), `n (%)`)
  }
  
  return(freq_table)
}

# ==============================================================================
# Listing Generation Functions
# ==============================================================================

#' Create Data Listing
#' @param data Data frame
#' @param title Listing title
#' @param columns Columns to include
#' @param sort_vars Variables to sort by
#' @return Formatted listing
create_listing <- function(data, title, columns = NULL, sort_vars = NULL) {
  
  # Select columns
  if (!is.null(columns)) {
    data <- data %>% select(all_of(columns))
  }
  
  # Sort data
  if (!is.null(sort_vars)) {
    data <- data %>% arrange(across(all_of(sort_vars)))
  }
  
  # Create listing
  listing <- flextable(data) %>%
    theme_vanilla() %>%
    fontsize(size = 8, part = "all") %>%
    font(fontname = "Courier New", part = "all") %>%
    align(align = "left", part = "all") %>%
    bold(part = "header") %>%
    autofit()
  
  # Add title
  listing <- add_header_lines(listing, values = title)
  listing <- bold(listing, i = 1, part = "header")
  
  return(listing)
}

#' Export Listing to RTF
#' @param listing_obj Flextable object
#' @param filename Output filename
#' @param path Output directory path
export_listing_rtf <- function(listing_obj, filename, path = "outputs/tlf/listings") {
  output_file <- file.path(path, paste0(filename, ".rtf"))
  save_as_rtf(listing_obj, path = output_file)
  cat(glue("✓ Listing saved: {basename(output_file)}\n"))
}

# ==============================================================================
# Figure Generation Functions
# ==============================================================================

#' Save Figure to Multiple Formats
#' @param plot_obj ggplot object
#' @param filename Output filename (without extension)
#' @param width Width in inches
#' @param height Height in inches
#' @param path Output directory path
save_figure <- function(plot_obj, filename, width = 8, height = 6, path = "outputs/tlf/figures") {
  
  # Save as PNG
  png_file <- file.path(path, paste0(filename, ".png"))
  ggsave(png_file, plot_obj, width = width, height = height, dpi = 300)
  cat(glue("✓ Figure saved: {basename(png_file)}\n"))
  
  # Save as PDF
  pdf_file <- file.path(path, paste0(filename, ".pdf"))
  ggsave(pdf_file, plot_obj, width = width, height = height)
  cat(glue("✓ Figure saved: {basename(pdf_file)}\n"))
  
  # Save as TIFF (for regulatory submission)
  tiff_file <- file.path(path, paste0(filename, ".tiff"))
  ggsave(tiff_file, plot_obj, width = width, height = height, dpi = 300, compression = "lzw")
  cat(glue("✓ Figure saved: {basename(tiff_file)}\n"))
}

# ==============================================================================
# P-value Formatting
# ==============================================================================

#' Format P-values for Regulatory Tables
#' @param p_value Numeric p-value
#' @return Formatted p-value string
format_pvalue <- function(p_value) {
  case_when(
    is.na(p_value) ~ "NA",
    p_value < 0.001 ~ "<0.001",
    p_value < 0.01 ~ sprintf("%.3f", p_value),
    TRUE ~ sprintf("%.2f", p_value)
  )
}

cat("\n✓ TLF utility functions loaded successfully\n\n")
