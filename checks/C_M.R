# =============================================================================
# CDB Migration Comparison Check
# Author: Siriyak (Converted from SAS to R)
# Date: 2026-01-14
# Original: C_M.txt (SAS code by Nitesh Kumar Sinha)
# Description: Compares ALSC and CDB dataset repositories and outputs differences
# =============================================================================

# Source dependencies (Adjusted for checks/ folder)
source("../Rchecks/config.R")
source("../Rchecks/utils.R")

# Main Comparison Functions -----------------------------------------------

#' Compare variable metadata between CDB and ALSC
#' @param cdb_data CDB dataset
#' @param alsc_data ALSC dataset
#' @param dataset_name Name of the dataset
#' @return List containing comparison results
compare_dataset_variables <- function(cdb_data, alsc_data, dataset_name) {
    # Get metadata for both datasets
    cdb_meta <- get_dataset_metadata(cdb_data, paste0("cdb_", dataset_name))
    alsc_meta <- get_dataset_metadata(alsc_data, paste0("inf_", dataset_name))

    # Find variables not in CDB
    var_not_in_cdb <- alsc_meta %>%
        filter(!(toupper(name) %in% toupper(cdb_meta$name))) %>%
        filter(!grepl("CDR", name, ignore.case = TRUE)) %>%
        select(name, memname)

    # Find variables in both (for comparison)
    var_in_both <- alsc_meta %>%
        filter(toupper(name) %in% toupper(cdb_meta$name)) %>%
        filter(!grepl("CDR", name, ignore.case = TRUE))

    # Match CDB metadata
    cdb_matched <- cdb_meta %>%
        filter(toupper(name) %in% toupper(var_in_both$name))

    # Create comparison
    if (nrow(var_in_both) > 0 && nrow(cdb_matched) > 0) {
        # Merge for comparison
        var_comparison <- var_in_both %>%
            left_join(
                cdb_matched,
                by = c("name" = "name"),
                suffix = c("", "_1")
            ) %>%
            mutate(
                flag = case_when(
                    type != type_1 & length != length_1 ~ "Type and Length mismatch",
                    type != type_1 ~ "Type mismatch",
                    length != length_1 ~ "Length mismatch",
                    TRUE ~ "Type and Length matching"
                )
            )

        # Apply length issue filter if needed
        if (LENGTH_ISSUE_NEEDED == "N") {
            var_comparison <- var_comparison %>%
                filter(!(flag == "Length mismatch" & length_1 == 6000))
        }
    } else {
        var_comparison <- data.frame()
    }

    return(list(
        var_not_in_cdb = var_not_in_cdb,
        var_comparison = var_comparison
    ))
}

#' Compare observation counts between datasets
#' @param cdb_data CDB dataset
#' @param alsc_data ALSC dataset
#' @param dataset_name Name of the dataset
#' @return Data frame with observation comparison
compare_observations <- function(cdb_data, alsc_data, dataset_name) {
    obs_summary <- data.frame(
        memname = paste0("inf_", toupper(dataset_name)),
        nobs = nrow(alsc_data),
        memname_1 = paste0("cdb_", toupper(dataset_name)),
        nobs_1 = nrow(cdb_data),
        stringsAsFactors = FALSE
    )

    obs_summary$flag <- ifelse(
        obs_summary$nobs != obs_summary$nobs_1,
        "Uneven observations",
        "Even observations"
    )

    return(obs_summary)
}

#' Run complete dataset comparison
#' @param cdb_datasets List of CDB datasets
#' @param alsc_datasets List of ALSC datasets
#' @param common_datasets Vector of common dataset names
#' @return List containing all comparison results
run_dataset_comparison <- function(cdb_datasets, alsc_datasets, common_datasets) {
    log_section("VALIDATION CHECK: CDB Migration Comparison")

    # Initialize result lists
    all_var_not_in_cdb <- list()
    all_var_comparison <- list()
    all_obs_comparison <- list()

    # Process each common dataset
    for (ds_name in common_datasets) {
        # Get dataset names with prefixes
        cdb_name <- paste0("cdb_", tolower(ds_name))
        alsc_name <- paste0("inf_", tolower(ds_name))

        log_message(paste("Comparing dataset:", ds_name))

        # Skip if either dataset is missing
        if (!(cdb_name %in% names(cdb_datasets)) ||
            !(alsc_name %in% names(alsc_datasets))) {
            warning(paste("Skipping", ds_name, "- dataset not found"))
            next
        }

        cdb_data <- cdb_datasets[[cdb_name]]
        alsc_data <- alsc_datasets[[alsc_name]]

        # Compare variables
        var_comparison <- compare_dataset_variables(cdb_data, alsc_data, ds_name)

        if (nrow(var_comparison$var_not_in_cdb) > 0) {
            all_var_not_in_cdb[[ds_name]] <- var_comparison$var_not_in_cdb
        }

        if (nrow(var_comparison$var_comparison) > 0) {
            all_var_comparison[[ds_name]] <- var_comparison$var_comparison
        }

        # Compare observations
        obs_comparison <- compare_observations(cdb_data, alsc_data, ds_name)
        all_obs_comparison[[ds_name]] <- obs_comparison
    }

    # Combine all results
    var_not_in_cdb_final <- if (length(all_var_not_in_cdb) > 0) {
        do.call(rbind, all_var_not_in_cdb)
    } else {
        data.frame(memname = character(), name = character())
    }

    var_in_cdb_final <- if (length(all_var_comparison) > 0) {
        do.call(rbind, all_var_comparison)
    } else {
        data.frame()
    }

    obs_summary_final <- if (length(all_obs_comparison) > 0) {
        do.call(rbind, all_obs_comparison)
    } else {
        data.frame()
    }

    log_message(paste("Comparison complete:", length(common_datasets), "datasets processed"))

    return(list(
        var_not_in_cdb = var_not_in_cdb_final,
        var_in_cdb = var_in_cdb_final,
        obs_summary = obs_summary_final
    ))
}

#' Generate CDB migration summary report
#' @param comparison_results Results from run_dataset_comparison
#' @param metadata Metadata from preprocessing
#' @return Path to generated Excel file
generate_migration_report <- function(comparison_results, metadata) {
    log_section("GENERATING MIGRATION SUMMARY REPORT")

    # Prepare output filename
    output_file <- get_output_path(
        paste0("cdb_migration_summary_", get_date_string(), ".xlsx")
    )

    # Prepare data for export
    report_data <- list(
        "missing_ds_in_cdb_summary" = metadata$ds_not_in_cdb,
        "missing_ds_in_alsc_summary" = metadata$ds_not_in_alsc,
        "var_not_in_cdb" = comparison_results$var_not_in_cdb,
        "var_in_cdb" = comparison_results$var_in_cdb,
        "obs_summary" = comparison_results$obs_summary
    )

    # Export to Excel
    export_to_excel(report_data, output_file)

    log_message(paste("Migration report generated:", output_file))

    return(output_file)
}

#' Main execution function for CDB migration comparison
#' @param preprocessing_results Results from preprocessing phase
#' @return List containing comparison results and report path
execute_cdb_migration_check <- function(preprocessing_results) {
    # Extract data from preprocessing
    cdb_datasets <- preprocessing_results$cdb_datasets
    alsc_datasets <- preprocessing_results$alsc_datasets
    metadata <- preprocessing_results$metadata

    # Run comparison
    comparison_results <- run_dataset_comparison(
        cdb_datasets,
        alsc_datasets,
        metadata$common_ds
    )

    # Generate report
    report_path <- generate_migration_report(comparison_results, metadata)

    return(list(
        comparison_results = comparison_results,
        report_path = report_path
    ))
}
