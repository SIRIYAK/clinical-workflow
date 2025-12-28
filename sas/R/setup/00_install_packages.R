# ==============================================================================
# SDTM/ADaM/BDM Automation Framework
# Script: 00_install_packages.R
# Purpose: Install and load all required R packages
# ==============================================================================

cat("\n========================================\n")
cat("Installing Required Packages\n")
cat("========================================\n\n")

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages) > 0) {
    cat("Installing:", paste(new_packages, collapse = ", "), "\n")
    install.packages(new_packages, dependencies = TRUE, repos = "https://cloud.r-project.org/")
  } else {
    cat("All packages already installed.\n")
  }
}

# ==============================================================================
# 1. Pharmaverse Packages
# ==============================================================================
cat("\n[1/6] Installing Pharmaverse packages...\n")

pharmaverse_packages <- c(
  "admiral",      # ADaM dataset creation
  "admiraldev",   # Development utilities for admiral
  "metacore",     # Metadata management
  "metatools",    # Metadata utilities
  "xportr"        # Export to XPT format
)

install_if_missing(pharmaverse_packages)

# ==============================================================================
# 2. Data I/O Packages
# ==============================================================================
cat("\n[2/6] Installing Data I/O packages...\n")

io_packages <- c(
  "haven",        # Read/write SAS datasets
  "readr",        # Read CSV files
  "readxl",       # Read Excel files
  "writexl"       # Write Excel files
)

install_if_missing(io_packages)

# ==============================================================================
# 3. Tidyverse Packages
# ==============================================================================
cat("\n[3/6] Installing Tidyverse packages...\n")

tidyverse_packages <- c(
  "dplyr",        # Data manipulation
  "tidyr",        # Data tidying
  "purrr",        # Functional programming
  "stringr",      # String manipulation
  "ggplot2",      # Data visualization
  "tibble"        # Modern data frames
)

install_if_missing(tidyverse_packages)

# ==============================================================================
# 4. Validation Packages
# ==============================================================================
cat("\n[4/6] Installing Validation packages...\n")

validation_packages <- c(
  "assertr",      # Data validation
  "pointblank",   # Data quality assessment
  "validate"      # Data validation rules
)

install_if_missing(validation_packages)

# ==============================================================================
# 5. Utility Packages
# ==============================================================================
cat("\n[5/6] Installing Utility packages...\n")

utility_packages <- c(
  "lubridate",    # Date/time manipulation
  "janitor",      # Data cleaning
  "glue",         # String interpolation
  "fs",           # File system operations
  "cli",          # Command line interface
  "here"          # Project-relative paths
)

install_if_missing(utility_packages)

# ==============================================================================
# 6. Reporting Packages
# ==============================================================================
cat("\n[6/6] Installing Reporting packages...\n")

reporting_packages <- c(
  "rmarkdown",    # Dynamic documents
  "knitr",        # Report generation
  "DT",           # Interactive tables
  "gt"            # Grammar of tables
)

install_if_missing(reporting_packages)

# ==============================================================================
# Load All Packages
# ==============================================================================
cat("\n========================================\n")
cat("Loading Packages\n")
cat("========================================\n\n")

all_packages <- c(
  pharmaverse_packages,
  io_packages,
  tidyverse_packages,
  validation_packages,
  utility_packages,
  reporting_packages
)

loaded_successfully <- sapply(all_packages, function(pkg) {
  result <- suppressPackageStartupMessages(
    suppressWarnings(
      require(pkg, character.only = TRUE, quietly = TRUE)
    )
  )
  if(result) {
    cat("✓", pkg, "\n")
  } else {
    cat("✗", pkg, "FAILED TO LOAD\n")
  }
  return(result)
})

# ==============================================================================
# Summary
# ==============================================================================
cat("\n========================================\n")
cat("Package Installation Summary\n")
cat("========================================\n")
cat("Total packages:", length(all_packages), "\n")
cat("Successfully loaded:", sum(loaded_successfully), "\n")
cat("Failed to load:", sum(!loaded_successfully), "\n")

if(sum(!loaded_successfully) > 0) {
  cat("\nFailed packages:\n")
  cat(paste(names(loaded_successfully)[!loaded_successfully], collapse = ", "), "\n")
  warning("Some packages failed to load. Please check installation.")
} else {
  cat("\n✓ All packages loaded successfully!\n")
}

cat("========================================\n\n")
