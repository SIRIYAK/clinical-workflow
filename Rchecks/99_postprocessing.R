# =============================================================================
# Post-Processing Functions for Data Validation
# Author: Siriyak
# Date: 2026-01-14
# Description: Post-processing steps including result aggregation, summary
#              generation, and final reporting
# =============================================================================

# Source dependencies -----------------------------------------------------
source("config.R")
source("utils.R")

# Post-Processing Functions -----------------------------------------------

#' Aggregate validation results
#' @param all_results List containing all validation check results
#' @return Aggregated summary data frame
aggregate_validation_results <- function(all_results) {
    log_section("POST-PROCESSING: Aggregating Validation Results")

    # Initialize summary
    summary_list <- list()

    # CDB Migration Check Summary
    if (!is.null(all_results$cdb_migration)) {
        migration_summary <- data.frame(
            check_name = "CDB Migration Comparison",
            status = "COMPLETED",
            n_datasets_compared = length(all_results$preprocessing$metadata$common_ds),
            n_missing_in_cdb = nrow(all_results$preprocessing$metadata$ds_not_in_cdb),
            n_missing_in_alsc = nrow(all_results$preprocessing$metadata$ds_not_in_alsc),
            n_variable_mismatches = nrow(all_results$cdb_migration$comparison_results$var_in_cdb),
            n_obs_mismatches = sum(
                all_results$cdb_migration$comparison_results$obs_summary$flag == "Uneven observations"
            ),
            stringsAsFactors = FALSE
        )
        summary_list$migration <- migration_summary
    }

    # Data Quality Check Summary
    if (!is.null(all_results$data_quality)) {
        quality_summary <- data.frame(
            check_name = "Data Quality Validation",
            status = "COMPLETED",
            n_datasets_checked = length(all_results$preprocessing$cdb_datasets),
            n_missing_value_issues = nrow(all_results$data_quality$quality_results$missing_values),
            n_duplicate_issues = nrow(all_results$data_quality$quality_results$duplicates),
            n_date_issues = nrow(all_results$data_quality$quality_results$date_issues),
            n_type_issues = nrow(all_results$data_quality$quality_results$type_issues),
            n_outlier_issues = nrow(all_results$data_quality$quality_results$outliers),
            stringsAsFactors = FALSE
        )
        summary_list$quality <- quality_summary
    }

    log_message("Validation results aggregated successfully")

    return(summary_list)
}

#' Create executive summary
#' @param all_results List containing all validation check results
#' @param summary_stats Aggregated summary statistics
#' @return Data frame with executive summary
create_executive_summary <- function(all_results, summary_stats) {
    log_section("POST-PROCESSING: Creating Executive Summary")

    # Calculate overall statistics
    total_datasets_processed <- length(all_results$preprocessing$cdb_datasets) +
        length(all_results$preprocessing$alsc_datasets)

    total_issues <- 0
    critical_issues <- 0

    # Count issues from migration check
    if (!is.null(summary_stats$migration)) {
        migration_issues <- summary_stats$migration$n_variable_mismatches +
            summary_stats$migration$n_obs_mismatches
        total_issues <- total_issues + migration_issues

        # Critical: observation mismatches
        critical_issues <- critical_issues + summary_stats$migration$n_obs_mismatches
    }

    # Count issues from quality check
    if (!is.null(summary_stats$quality)) {
        quality_issues <- summary_stats$quality$n_missing_value_issues +
            summary_stats$quality$n_duplicate_issues +
            summary_stats$quality$n_date_issues +
            summary_stats$quality$n_type_issues
        total_issues <- total_issues + quality_issues

        # Critical: duplicates and type issues
        critical_issues <- critical_issues +
            summary_stats$quality$n_duplicate_issues +
            summary_stats$quality$n_type_issues
    }

    # Determine overall status
    validation_status <- if (critical_issues > 0) {
        "ISSUES FOUND - REVIEW REQUIRED"
    } else if (total_issues > 0) {
        "WARNINGS - MINOR ISSUES DETECTED"
    } else {
        "PASSED - NO ISSUES DETECTED"
    }

    # Create executive summary
    exec_summary <- data.frame(
        session_id = SESSION_ID,
        validation_date = format(Sys.Date(), "%Y-%m-%d"),
        validation_time = format(SESSION_START, "%H:%M:%S"),
        study = STUDY,
        compound = COMP,
        total_datasets_processed = total_datasets_processed,
        total_issues_found = total_issues,
        critical_issues = critical_issues,
        validation_status = validation_status,
        stringsAsFactors = FALSE
    )

    log_message(paste("Validation Status:", validation_status))
    log_message(paste("Total Issues:", total_issues, "| Critical:", critical_issues))

    return(exec_summary)
}

#' Generate consolidated final report
#' @param all_results List containing all validation check results
#' @return Path to generated consolidated Excel report
generate_final_report <- function(all_results) {
    log_section("POST-PROCESSING: Generating Final Consolidated Report")

    # Aggregate results
    summary_stats <- aggregate_validation_results(all_results)

    # Create executive summary
    exec_summary <- create_executive_summary(all_results, summary_stats)

    # Prepare output filename
    output_file <- get_output_path(
        paste0("validation_final_report_", get_date_string(), ".xlsx")
    )

    # Prepare comprehensive report data
    report_data <- list(
        "Executive_Summary" = exec_summary
    )

    # Add migration check details
    if (!is.null(summary_stats$migration)) {
        report_data$"Migration_Summary" <- summary_stats$migration
    }

    # Add quality check details
    if (!is.null(summary_stats$quality)) {
        report_data$"Quality_Summary" <- summary_stats$quality
    }

    # Add detailed results from migration check
    if (!is.null(all_results$cdb_migration)) {
        report_data$"Missing_Datasets_CDB" <- all_results$preprocessing$metadata$ds_not_in_cdb
        report_data$"Missing_Datasets_ALSC" <- all_results$preprocessing$metadata$ds_not_in_alsc
        report_data$"Variable_Mismatches" <- all_results$cdb_migration$comparison_results$var_in_cdb
        report_data$"Observation_Mismatches" <- all_results$cdb_migration$comparison_results$obs_summary
    }

    # Add detailed results from quality check
    if (!is.null(all_results$data_quality)) {
        qr <- all_results$data_quality$quality_results

        if (nrow(qr$missing_values) > 0) {
            report_data$"Missing_Values" <- qr$missing_values
        }
        if (nrow(qr$duplicates) > 0) {
            report_data$"Duplicates" <- qr$duplicates
        }
        if (nrow(qr$date_issues) > 0) {
            report_data$"Date_Issues" <- qr$date_issues
        }
        if (nrow(qr$type_issues) > 0) {
            report_data$"Type_Issues" <- qr$type_issues
        }
        if (nrow(qr$outliers) > 0) {
            report_data$"Outliers" <- qr$outliers
        }
    }

    # Export consolidated report
    export_to_excel(report_data, output_file)

    log_message(paste("Final consolidated report generated:", output_file))

    return(output_file)
}

#' Print validation summary to console
#' @param all_results List containing all validation check results
print_validation_summary <- function(all_results) {
    log_section("VALIDATION SUMMARY")

    # Aggregate results
    summary_stats <- aggregate_validation_results(all_results)

    # Create executive summary
    exec_summary <- create_executive_summary(all_results, summary_stats)

    # Print summary
    cat("\n")
    cat("============================================================\n")
    cat("               VALIDATION SUMMARY REPORT                    \n")
    cat("============================================================\n")
    cat("\n")
    cat("Study:", exec_summary$study, "\n")
    cat("Compound:", exec_summary$compound, "\n")
    cat("Date:", exec_summary$validation_date, exec_summary$validation_time, "\n")
    cat("Session ID:", exec_summary$session_id, "\n")
    cat("\n")
    cat("------------------------------------------------------------\n")
    cat("OVERALL STATUS:", exec_summary$validation_status, "\n")
    cat("------------------------------------------------------------\n")
    cat("\n")
    cat("Datasets Processed:", exec_summary$total_datasets_processed, "\n")
    cat("Total Issues Found:", exec_summary$total_issues_found, "\n")
    cat("Critical Issues:", exec_summary$critical_issues, "\n")
    cat("\n")

    # Migration details
    if (!is.null(summary_stats$migration)) {
        cat("========== CDB Migration Comparison ==========\n")
        cat("Datasets Compared:", summary_stats$migration$n_datasets_compared, "\n")
        cat("Missing in CDB:", summary_stats$migration$n_missing_in_cdb, "\n")
        cat("Missing in ALSC:", summary_stats$migration$n_missing_in_alsc, "\n")
        cat("Variable Mismatches:", summary_stats$migration$n_variable_mismatches, "\n")
        cat("Observation Mismatches:", summary_stats$migration$n_obs_mismatches, "\n")
        cat("\n")
    }

    # Quality details
    if (!is.null(summary_stats$quality)) {
        cat("========== Data Quality Validation ==========\n")
        cat("Datasets Checked:", summary_stats$quality$n_datasets_checked, "\n")
        cat("Missing Value Issues:", summary_stats$quality$n_missing_value_issues, "\n")
        cat("Duplicate Issues:", summary_stats$quality$n_duplicate_issues, "\n")
        cat("Date Issues:", summary_stats$quality$n_date_issues, "\n")
        cat("Type Issues:", summary_stats$quality$n_type_issues, "\n")
        cat("Outlier Warnings:", summary_stats$quality$n_outlier_issues, "\n")
        cat("\n")
    }

    cat("============================================================\n")
    cat("For detailed results, please review the output reports.\n")
    cat("============================================================\n")
    cat("\n")
}

#' Cleanup temporary files and prepare for next run
#' @param all_results List containing all validation check results
cleanup_session <- function(all_results) {
    log_section("POST-PROCESSING: Cleanup")

    # Record session end time
    session_end <- Sys.time()
    duration <- difftime(session_end, SESSION_START, units = "mins")

    log_message(paste("Session duration:", round(duration, 2), "minutes"))
    log_message("Cleanup completed")

    return(invisible(TRUE))
}

#' Main post-processing function
#' @param all_results List containing all validation check results
#' @return List with final report path and summary
run_postprocessing <- function(all_results) {
    log_section("STARTING POST-PROCESSING PHASE")

    # Generate final consolidated report
    final_report <- generate_final_report(all_results)

    # Print summary to console
    print_validation_summary(all_results)

    # Cleanup
    cleanup_session(all_results)

    log_section("POST-PROCESSING PHASE COMPLETED")

    return(list(
        final_report_path = final_report,
        session_id = SESSION_ID
    ))
}
