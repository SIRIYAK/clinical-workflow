# =============================================================================
# Data Quality Validation Checks
# Author: Siriyak
# Date: 2026-01-14
# Description: Comprehensive data quality checks for identifying issues in data
# =============================================================================

# Source dependencies -----------------------------------------------------
source("config.R")
source("utils.R")

# Data Quality Check Functions --------------------------------------------

#' Check for missing values across datasets
#' @param dataset_list Named list of datasets
#' @return Data frame with missing value summary
check_missing_values <- function(dataset_list) {
    log_message("Running missing value checks...")

    all_missing <- lapply(names(dataset_list), function(ds_name) {
        data <- dataset_list[[ds_name]]

        missing_summary <- calc_missing_pct(data)
        missing_summary$dataset <- ds_name

        # Filter to only variables with missing values
        missing_summary <- missing_summary %>%
            filter(n_missing > 0) %>%
            select(dataset, variable, n_missing, n_total, pct_missing)

        return(missing_summary)
    })

    # Combine all results
    all_missing_df <- do.call(rbind, all_missing)

    if (nrow(all_missing_df) > 0) {
        all_missing_df <- all_missing_df[order(-all_missing_df$pct_missing), ]

        # Flag high missing percentages
        all_missing_df$flag <- ifelse(
            all_missing_df$pct_missing > MAX_MISSING_PCT,
            "HIGH",
            "MODERATE"
        )
    }

    log_message(paste("Found", nrow(all_missing_df), "variables with missing values"))

    return(all_missing_df)
}

#' Check for duplicate records
#' @param dataset_list Named list of datasets
#' @param key_list Optional named list of key variables for each dataset
#' @return Data frame with duplicate summary
check_duplicates <- function(dataset_list, key_list = NULL) {
    log_message("Running duplicate record checks...")

    all_duplicates <- lapply(names(dataset_list), function(ds_name) {
        data <- dataset_list[[ds_name]]

        # Use provided keys or all columns
        key_vars <- if (!is.null(key_list) && ds_name %in% names(key_list)) {
            key_list[[ds_name]]
        } else {
            names(data)
        }

        # Find duplicates
        duplicates <- find_duplicates(data, key_vars)

        # Create summary
        if (nrow(duplicates) > 0) {
            n_dup_keys <- sum(duplicated(duplicates[, key_vars]) |
                duplicated(duplicates[, key_vars], fromLast = TRUE)) / 2

            return(data.frame(
                dataset = ds_name,
                n_duplicate_records = nrow(duplicates),
                n_duplicate_keys = n_dup_keys,
                key_variables = paste(key_vars, collapse = ", "),
                stringsAsFactors = FALSE
            ))
        } else {
            return(NULL)
        }
    })

    # Remove NULL entries
    all_duplicates <- all_duplicates[!sapply(all_duplicates, is.null)]

    if (length(all_duplicates) > 0) {
        all_duplicates_df <- do.call(rbind, all_duplicates)
    } else {
        all_duplicates_df <- data.frame(
            dataset = character(),
            n_duplicate_records = numeric(),
            n_duplicate_keys = numeric(),
            key_variables = character()
        )
    }

    log_message(paste("Found duplicates in", nrow(all_duplicates_df), "datasets"))

    return(all_duplicates_df)
}

#' Check date variable consistency
#' @param dataset_list Named list of datasets
#' @return Data frame with date validation issues
check_date_consistency <- function(dataset_list) {
    log_message("Running date consistency checks...")

    all_date_issues <- lapply(names(dataset_list), function(ds_name) {
        data <- dataset_list[[ds_name]]

        # Identify date variables (common patterns)
        date_vars <- names(data)[grepl("date|dt$|_dt|_d$", names(data), ignore.case = TRUE)]

        if (length(date_vars) == 0) {
            return(NULL)
        }

        date_issues <- lapply(date_vars, function(var) {
            # Convert to date if character
            date_col <- data[[var]]

            # Try to identify format and validate
            if (is.character(date_col)) {
                # Check for common date formats
                invalid_dates <- sum(!is.na(date_col) & date_col != "" &
                    !grepl("^\\d{2,4}[-/]\\d{2}[-/]\\d{2,4}", date_col))

                if (invalid_dates > 0) {
                    return(data.frame(
                        dataset = ds_name,
                        variable = var,
                        issue = "Invalid date format",
                        n_issues = invalid_dates,
                        stringsAsFactors = FALSE
                    ))
                }
            }

            return(NULL)
        })

        date_issues <- date_issues[!sapply(date_issues, is.null)]

        if (length(date_issues) > 0) {
            return(do.call(rbind, date_issues))
        }

        return(NULL)
    })

    all_date_issues <- all_date_issues[!sapply(all_date_issues, is.null)]

    if (length(all_date_issues) > 0) {
        all_date_issues_df <- do.call(rbind, all_date_issues)
    } else {
        all_date_issues_df <- data.frame(
            dataset = character(),
            variable = character(),
            issue = character(),
            n_issues = numeric()
        )
    }

    log_message(paste("Found", nrow(all_date_issues_df), "date consistency issues"))

    return(all_date_issues_df)
}

#' Check data type consistency
#' @param dataset_list Named list of datasets
#' @return Data frame with data type issues
check_data_types <- function(dataset_list) {
    log_message("Running data type checks...")

    all_type_issues <- lapply(names(dataset_list), function(ds_name) {
        data <- dataset_list[[ds_name]]

        type_issues <- lapply(names(data), function(var) {
            col <- data[[var]]

            # Check if numeric variable has character data
            if (is.character(col)) {
                # Try to find columns that should be numeric
                non_missing <- col[!is.na(col) & col != ""]

                if (length(non_missing) > 0) {
                    # Check if most values are numeric
                    numeric_values <- suppressWarnings(as.numeric(non_missing))
                    pct_numeric <- sum(!is.na(numeric_values)) / length(non_missing) * 100

                    if (pct_numeric > 80 && pct_numeric < 100) {
                        return(data.frame(
                            dataset = ds_name,
                            variable = var,
                            issue = "Mixed numeric/character data",
                            pct_numeric = round(pct_numeric, 2),
                            stringsAsFactors = FALSE
                        ))
                    }
                }
            }

            return(NULL)
        })

        type_issues <- type_issues[!sapply(type_issues, is.null)]

        if (length(type_issues) > 0) {
            return(do.call(rbind, type_issues))
        }

        return(NULL)
    })

    all_type_issues <- all_type_issues[!sapply(all_type_issues, is.null)]

    if (length(all_type_issues) > 0) {
        all_type_issues_df <- do.call(rbind, all_type_issues)
    } else {
        all_type_issues_df <- data.frame(
            dataset = character(),
            variable = character(),
            issue = character(),
            pct_numeric = numeric()
        )
    }

    log_message(paste("Found", nrow(all_type_issues_df), "data type issues"))

    return(all_type_issues_df)
}

#' Check for outliers in numeric variables
#' @param dataset_list Named list of datasets
#' @return Data frame with outlier summary
check_outliers <- function(dataset_list) {
    log_message("Running outlier detection...")

    all_outliers <- lapply(names(dataset_list), function(ds_name) {
        data <- dataset_list[[ds_name]]

        # Get numeric columns
        numeric_cols <- names(data)[sapply(data, is.numeric)]

        if (length(numeric_cols) == 0) {
            return(NULL)
        }

        outlier_summary <- lapply(numeric_cols, function(var) {
            col <- data[[var]]
            col_clean <- col[!is.na(col)]

            if (length(col_clean) < 4) {
                return(NULL)
            }

            # Calculate IQR
            q1 <- quantile(col_clean, 0.25)
            q3 <- quantile(col_clean, 0.75)
            iqr <- q3 - q1

            # Identify outliers (1.5 * IQR rule)
            lower_bound <- q1 - 1.5 * iqr
            upper_bound <- q3 + 1.5 * iqr

            outliers <- sum(col_clean < lower_bound | col_clean > upper_bound)

            if (outliers > 0) {
                return(data.frame(
                    dataset = ds_name,
                    variable = var,
                    n_outliers = outliers,
                    pct_outliers = round(outliers / length(col_clean) * 100, 2),
                    lower_bound = round(lower_bound, 2),
                    upper_bound = round(upper_bound, 2),
                    stringsAsFactors = FALSE
                ))
            }

            return(NULL)
        })

        outlier_summary <- outlier_summary[!sapply(outlier_summary, is.null)]

        if (length(outlier_summary) > 0) {
            return(do.call(rbind, outlier_summary))
        }

        return(NULL)
    })

    all_outliers <- all_outliers[!sapply(all_outliers, is.null)]

    if (length(all_outliers) > 0) {
        all_outliers_df <- do.call(rbind, all_outliers)
        all_outliers_df <- all_outliers_df[order(-all_outliers_df$pct_outliers), ]
    } else {
        all_outliers_df <- data.frame(
            dataset = character(),
            variable = character(),
            n_outliers = numeric(),
            pct_outliers = numeric(),
            lower_bound = numeric(),
            upper_bound = numeric()
        )
    }

    log_message(paste("Found outliers in", nrow(all_outliers_df), "variables"))

    return(all_outliers_df)
}

#' Generate data quality summary report
#' @param quality_results List of quality check results
#' @return Path to generated Excel file
generate_quality_report <- function(quality_results) {
    log_section("GENERATING DATA QUALITY REPORT")

    # Prepare output filename
    output_file <- get_output_path(
        paste0("data_quality_report_", get_date_string(), ".xlsx")
    )

    # Prepare data for export
    report_data <- list(
        "missing_values" = quality_results$missing_values,
        "duplicates" = quality_results$duplicates,
        "date_issues" = quality_results$date_issues,
        "type_issues" = quality_results$type_issues,
        "outliers" = quality_results$outliers
    )

    # Export to Excel
    export_to_excel(report_data, output_file)

    log_message(paste("Data quality report generated:", output_file))

    return(output_file)
}

#' Main execution function for data quality checks
#' @param preprocessing_results Results from preprocessing phase
#' @param check_cdb If TRUE, check CDB datasets; if FALSE, check ALSC datasets
#' @return List containing quality check results and report path
execute_data_quality_checks <- function(preprocessing_results, check_cdb = TRUE) {
    log_section("VALIDATION CHECK: Data Quality")

    # Select which datasets to check
    dataset_list <- if (check_cdb) {
        preprocessing_results$cdb_datasets
    } else {
        preprocessing_results$alsc_datasets
    }

    if (length(dataset_list) == 0) {
        warning("No datasets available for quality checks")
        return(list(quality_results = NULL, report_path = NULL))
    }

    # Run all quality checks
    quality_results <- list(
        missing_values = check_missing_values(dataset_list),
        duplicates = check_duplicates(dataset_list),
        date_issues = check_date_consistency(dataset_list),
        type_issues = check_data_types(dataset_list),
        outliers = check_outliers(dataset_list)
    )

    # Generate report
    report_path <- generate_quality_report(quality_results)

    return(list(
        quality_results = quality_results,
        report_path = report_path
    ))
}
