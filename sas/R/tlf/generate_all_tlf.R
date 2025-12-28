# ==============================================================================
# Master TLF Generation Script
# Script: generate_all_tlf.R
# Purpose: Generate all Tables, Listings, and Figures
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n")
cat("================================================================================\n")
cat("  TLF (Tables, Listings, Figures) Generation\n")
cat("================================================================================\n\n")

# Track execution time
start_time <- Sys.time()

# ==============================================================================
# Generate Tables
# ==============================================================================

cat("[Phase 1] Generating Tables\n")
cat("================================================================================\n\n")

tables <- c(
  "R/tlf/table_demographics.R",
  "R/tlf/table_disposition.R",
  "R/tlf/table_ae_summary.R",
  "R/tlf/table_ae_by_soc.R",
  "R/tlf/table_vital_signs.R",
  "R/tlf/table_lab_shift.R",
  "R/tlf/table_anova_lab.R"
)

for (table_script in tables) {
  if (file.exists(table_script)) {
    cat(glue("\nExecuting: {basename(table_script)}\n"))
    cat(strrep("-", 80), "\n")
    
    tryCatch({
      source(table_script, echo = FALSE)
      cat("✓ Success\n")
    }, error = function(e) {
      cat(glue("✗ Error: {e$message}\n"))
    })
  }
}

# ==============================================================================
# Generate Listings
# ==============================================================================

cat("\n[Phase 2] Generating Listings\n")
cat("================================================================================\n\n")

listings <- c(
  "R/tlf/listing_ae.R",
  "R/tlf/listing_cm.R",
  "R/tlf/listing_lab.R"
)

for (listing_script in listings) {
  if (file.exists(listing_script)) {
    cat(glue("\nExecuting: {basename(listing_script)}\n"))
    cat(strrep("-", 80), "\n")
    
    tryCatch({
      source(listing_script, echo = FALSE)
      cat("✓ Success\n")
    }, error = function(e) {
      cat(glue("✗ Error: {e$message}\n"))
    })
  }
}

# ==============================================================================
# Generate Figures
# ==============================================================================

cat("\n[Phase 3] Generating Figures\n")
cat("================================================================================\n\n")

figures <- c(
  "R/tlf/figure_lab_boxplot.R",
  "R/tlf/figure_ae_barchart.R",
  "R/tlf/figure_mean_change_time.R",
  "R/tlf/figure_km_survival.R",
  "R/tlf/figure_forest_plot.R",
  "R/tlf/figure_waterfall_plot.R",
  "R/tlf/figure_swimmer_plot.R"
)

for (figure_script in figures) {
  if (file.exists(figure_script)) {
    cat(glue("\nExecuting: {basename(figure_script)}\n"))
    cat(strrep("-", 80), "\n")
    
    tryCatch({
      source(figure_script, echo = FALSE)
      cat("✓ Success\n")
    }, error = function(e) {
      cat(glue("✗ Error: {e$message}\n"))
    })
  }
}

# ==============================================================================
# Summary
# ==============================================================================

end_time <- Sys.time()
elapsed <- difftime(end_time, start_time, units = "mins")

cat("\n")
cat("================================================================================\n")
cat("  TLF Generation Summary\n")
cat("================================================================================\n\n")

cat(glue("Start Time: {format(start_time, '%Y-%m-%d %H:%M:%S')}\n"))
cat(glue("End Time: {format(end_time, '%Y-%m-%d %H:%M:%S')}\n"))
cat(glue("Duration: {round(elapsed, 2)} minutes\n\n"))

# Count generated files
table_files <- list.files("outputs/tlf/tables", pattern = "\\.(rtf|docx)$")
listing_files <- list.files("outputs/tlf/listings", pattern = "\\.rtf$")
figure_files <- list.files("outputs/tlf/figures", pattern = "\\.(png|pdf|tiff)$")

cat("Generated Outputs:\n")
cat(sprintf("  Tables: %d\n", length(table_files)))
cat(sprintf("  Listings: %d\n", length(listing_files)))
cat(sprintf("  Figures: %d\n", length(figure_files)))

cat("\nOutput Locations:\n")
cat("  Tables: outputs/tlf/tables/\n")
cat("  Listings: outputs/tlf/listings/\n")
cat("  Figures: outputs/tlf/figures/\n")

cat("\n✓ TLF generation complete!\n")
cat("================================================================================\n\n")
