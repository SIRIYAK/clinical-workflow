# =============================================================================
# Master Script: Run All Data Validation Checks
# Author: Siriyak
# Date: 2026-01-14
# Description: Orchestrates all validation checks with preprocessing,
#              execution, and post-processing phases
# =============================================================================

# Clear environment (optional - comment out if you want to preserve workspace)
# rm(list = ls())

# Load required packages --------------------------------------------------
cat("\n")
cat("============================================================\n")
cat("      DATA VALIDATION FRAMEWORK - MASTER EXECUTION         \n")
cat("============================================================\n")
cat("\n")

required_packages <- c(
    "haven", "openxlsx", "dplyr", "tidyr", "purrr",
    "readr", "readxl", "janitor", "stringr"
)

cat("Checking required packages...\n")
for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        cat(paste("Installing package:", pkg, "\n"))
        install.packages(pkg, repos = "https://cloud.r-project.org/")
    }
}

cat("All required packages available.\n\n")

# Source all validation scripts in order ----------------------------------

# Get script directory
script_dir <- getwd()

cat("Sourcing validation scripts...\n")

# Core utilities
source(file.path(script_dir, "config.R"))
source(file.path(script_dir, "utils.R"))

# Processing phases
source(file.path(script_dir, "00_preprocessing.R"))
source(file.path(script_dir, "01_CDB_Migration_Comparison.R"))
source(file.path(script_dir, "02_Data_Quality_Checks.R"))
source(file.path(script_dir, "03_Compare_Tool_Functions.R"))
source(file.path(script_dir, "04_Fetch_CDISC_Standards.R"))
source(file.path(script_dir, "05_Validate_Against_Std.R"))
source(file.path(script_dir, "99_postprocessing.R"))

cat("All scripts loaded successfully.\n\n")

# Main Execution Function -------------------------------------------------

#' Run complete data validation workflow
#' @param run_migration Logical, run CDB migration comparison (default TRUE)
#' @param run_quality Logical, run data quality checks (default TRUE)
#' @param run_cdisc Logical, run CDISC compliance checks (default TRUE)
#' @param update_standards Logical, fetch latest standards from API (default FALSE)
#' @param quality_target Character, "cdb" or "alsc" for quality checks (default "cdb")
#' @return List with all validation results
run_all_validation_checks <- function(run_migration = TRUE,
                                      run_quality = TRUE,
                                      run_cdisc = TRUE,
                                      update_standards = FALSE,
                                      quality_target = "cdb") {
    # Start timestamp
    start_time <- Sys.time()

    cat("\n")
    cat("============================================================\n")
    cat("           STARTING VALIDATION WORKFLOW                     \n")
    cat("============================================================\n")
    cat("\n")
    cat("Timestamp:", format(start_time, "%Y-%m-%d %H:%M:%S"), "\n")
    cat("\n")

    # Initialize results list
    all_results <- list()

    # PHASE 1: PREPROCESSING ----------------------------------------------
    tryCatch(
        {
            preprocessing_results <- run_preprocessing()
            all_results$preprocessing <- preprocessing_results
        },
        error = function(e) {
            cat("\n!! ERROR in preprocessing phase !!\n")
            cat(e$message, "\n")
            stop("Validation workflow failed during preprocessing.")
        }
    )

    # PHASE 2: VALIDATION CHECKS ------------------------------------------

    # CDB Migration Comparison
    if (run_migration) {
        tryCatch(
            {
                migration_results <- execute_cdb_migration_check(preprocessing_results)
                all_results$cdb_migration <- migration_results
            },
            error = function(e) {
                cat("\n!! ERROR in CDB migration check !!\n")
                cat(e$message, "\n")
                all_results$cdb_migration <- NULL
            }
        )
    }

    # Data Quality Checks
    if (run_quality) {
        tryCatch(
            {
                check_cdb <- (quality_target == "cdb")
                quality_results <- execute_data_quality_checks(preprocessing_results, check_cdb)
                all_results$data_quality <- quality_results
            },
            error = function(e) {
                cat("\n!! ERROR in data quality check !!\n")
                cat(e$message, "\n")
                all_results$data_quality <- NULL
            }
        )
    }

    # CDISC Compliance Checks
    if (run_cdisc) {
        tryCatch(
            {
                # Update standards if requested
                if (update_standards) {
                    run_fetch_standards()
                }

                # Run validation
                cdisc_results <- run_cdisc_validation()
                all_results$cdisc_validation <- cdisc_results
            },
            error = function(e) {
                cat("\n!! ERROR in CDISC validation !!\n")
                cat(e$message, "\n")
                all_results$cdisc_validation <- NULL
            }
        )
    }

    # PHASE 3: POST-PROCESSING --------------------------------------------
    tryCatch(
        {
            postprocessing_results <- run_postprocessing(all_results)
            all_results$postprocessing <- postprocessing_results
        },
        error = function(e) {
            cat("\n!! ERROR in post-processing phase !!\n")
            cat(e$message, "\n")
            all_results$postprocessing <- NULL
        }
    )

    # Final summary
    end_time <- Sys.time()
    duration <- difftime(end_time, start_time, units = "mins")

    cat("\n")
    cat("============================================================\n")
    cat("         VALIDATION WORKFLOW COMPLETED                      \n")
    cat("============================================================\n")
    cat("\n")
    cat("Total execution time:", round(duration, 2), "minutes\n")

    if (!is.null(all_results$postprocessing$final_report_path)) {
        cat("Final report:", all_results$postprocessing$final_report_path, "\n")
    }

    cat("\n")

    return(invisible(all_results))
}

# Execute Validation ------------------------------------------------------

# Run with default settings (both migration and quality checks)
validation_results <- run_all_validation_checks()

# Alternative execution options (uncomment as needed):

# Run only migration comparison:
# validation_results <- run_all_validation_checks(run_migration = TRUE, run_quality = FALSE)

# Run only quality checks on ALSC data:
# validation_results <- run_all_validation_checks(run_migration = FALSE,
#                                                  run_quality = TRUE,
#                                                  quality_target = "alsc")

# Custom execution:
# validation_results <- run_all_validation_checks(
#   run_migration = TRUE,
#   run_quality = TRUE,
#   quality_target = "cdb"
# )

cat("\n")
cat("Validation results stored in 'validation_results' object.\n")
cat("Access individual results:\n")
cat("  - validation_results$preprocessing\n")
cat("  - validation_results$cdb_migration\n")
cat("  - validation_results$data_quality\n")
cat("  - validation_results$postprocessing\n")
cat("\n")
