# =============================================================================
# Utility Functions for R Data Validation Checks
# Author: Siriyak
# Date: 2026-01-14
# Description: Common utility functions used across validation checks
# =============================================================================

# Required Libraries ------------------------------------------------------
suppressPackageStartupMessages({
    library(haven) # For reading SAS datasets
    library(openxlsx) # For Excel output
    library(dplyr) # For data manipulation
    library(tidyr) # For data tidying
    library(purrr) # For functional programming
    library(readr) # For reading delimited files
    library(readxl) # For reading Excel files
})

# Data Reading Functions --------------------------------------------------

#' Read SAS dataset
#' @param path Path to SAS dataset (.sas7bdat file)
#' @return Data frame
read_sas_dataset <- function(path) {
    if (!file.exists(path)) {
        stop(paste("File not found:", path))
    }

    tryCatch(
        {
            data <- haven::read_sas(path)
            message(paste("Successfully read:", basename(path)))
            return(as.data.frame(data))
        },
        error = function(e) {
            stop(paste("Error reading SAS file:", path, "\n", e$message))
        }
    )
}

#' Read all datasets from a directory
#' @param lib_path Path to directory containing SAS datasets
#' @param pattern File pattern to match (default: "\\.sas7bdat$")
#' @return Named list of data frames
read_library <- function(lib_path, pattern = "\\.sas7bdat$") {
    if (!dir.exists(lib_path)) {
        stop(paste("Directory not found:", lib_path))
    }

    files <- list.files(lib_path, pattern = pattern, full.names = TRUE)

    if (length(files) == 0) {
        warning(paste("No files matching pattern found in:", lib_path))
        return(list())
    }

    message(paste("Reading", length(files), "datasets from", lib_path))

    datasets <- lapply(files, function(f) {
        tryCatch(
            {
                read_sas_dataset(f)
            },
            error = function(e) {
                warning(paste("Failed to read:", basename(f)))
                NULL
            }
        )
    })

    names(datasets) <- tools::file_path_sans_ext(basename(files))

    # Remove NULL entries (failed reads)
    datasets <- datasets[!sapply(datasets, is.null)]

    return(datasets)
}

# Dataset Information Functions -------------------------------------------

#' Get dataset metadata
#' @param data Data frame
#' @param dataset_name Name of dataset
#' @return Data frame with variable metadata
get_dataset_metadata <- function(data, dataset_name = "UNKNOWN") {
    meta <- data.frame(
        memname = dataset_name,
        name = names(data),
        type = sapply(data, function(x) {
            if (is.numeric(x)) 1 else 2
        }),
        length = sapply(data, function(x) {
            if (is.character(x)) {
                max(nchar(as.character(x)), na.rm = TRUE)
            } else {
                8
            }
        }),
        stringsAsFactors = FALSE
    )

    # Add labels if available
    meta$label <- sapply(data, function(x) {
        lbl <- attr(x, "label")
        if (is.null(lbl)) "" else lbl
    })

    # Add formats if available
    meta$format <- sapply(data, function(x) {
        fmt <- attr(x, "format")
        if (is.null(fmt)) "" else fmt
    })

    return(meta)
}

#' Get observation count for datasets
#' @param dataset_list Named list of data frames
#' @return Data frame with dataset names and observation counts
get_obs_summary <- function(dataset_list) {
    obs_summary <- data.frame(
        memname = names(dataset_list),
        nobs = sapply(dataset_list, nrow),
        stringsAsFactors = FALSE
    )
    return(obs_summary)
}

# Excel Export Functions --------------------------------------------------

#' Export data to Excel with proper formatting
#' @param data_list Named list of data frames to export
#' @param file_path Output file path
#' @param sheet_names Optional vector of sheet names
#' @return Invisible TRUE on success
export_to_excel <- function(data_list, file_path, sheet_names = NULL) {
    # Create workbook
    wb <- createWorkbook()

    # Use provided sheet names or names from list
    if (is.null(sheet_names)) {
        sheet_names <- names(data_list)
    }

    # Ensure sheet names are valid (max 31 chars, no special chars)
    sheet_names <- substr(sheet_names, 1, 31)
    sheet_names <- gsub("[:\\\\/?\\*\\[\\]]", "_", sheet_names)

    # Add each data frame as a sheet
    for (i in seq_along(data_list)) {
        addWorksheet(wb, sheet_names[i])
        writeData(wb,
            sheet = i, x = data_list[[i]],
            startRow = 1, startCol = 1,
            headerStyle = createStyle(textDecoration = "bold")
        )

        # Freeze top row
        freezePane(wb, sheet = i, firstRow = TRUE)

        # Auto-size columns
        setColWidths(wb, sheet = i, cols = 1:ncol(data_list[[i]]), widths = "auto")
    }

    # Save workbook
    tryCatch(
        {
            saveWorkbook(wb, file_path, overwrite = TRUE)
            message(paste("Successfully exported to:", file_path))
            return(invisible(TRUE))
        },
        error = function(e) {
            stop(paste("Error saving Excel file:", e$message))
        }
    )
}

# Logging Functions -------------------------------------------------------

#' Write log message
#' @param message Message to log
#' @param level Log level (INFO, WARNING, ERROR)
log_message <- function(message, level = "INFO") {
    timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
    log_entry <- paste0("[", timestamp, "] [", level, "] ", message)
    cat(log_entry, "\n")
}

#' Log section header
#' @param section_name Name of the section
log_section <- function(section_name) {
    cat("\n")
    cat(paste(rep("=", 70), collapse = ""), "\n")
    cat(paste0("  ", section_name, "\n"))
    cat(paste(rep("=", 70), collapse = ""), "\n")
    cat("\n")
}

# Comparison Functions ----------------------------------------------------

#' Find common datasets between two lists
#' @param list1 First list of dataset names
#' @param list2 Second list of dataset names
#' @return Character vector of common dataset names
find_common_datasets <- function(list1, list2) {
    common <- intersect(toupper(list1), toupper(list2))
    return(common)
}

#' Find datasets in list1 not in list2
#' @param list1 First list of dataset names
#' @param list2 Second list of dataset names
#' @return Character vector of datasets only in list1
find_missing_datasets <- function(list1, list2) {
    missing <- setdiff(toupper(list1), toupper(list2))
    return(missing)
}

# Data Quality Functions --------------------------------------------------

#' Calculate missing value percentages
#' @param data Data frame
#' @return Data frame with variable names and missing percentages
calc_missing_pct <- function(data) {
    missing_summary <- data.frame(
        variable = names(data),
        n_missing = sapply(data, function(x) sum(is.na(x))),
        n_total = nrow(data),
        stringsAsFactors = FALSE
    )

    missing_summary$pct_missing <- round(
        (missing_summary$n_missing / missing_summary$n_total) * 100, 2
    )

    return(missing_summary[order(-missing_summary$pct_missing), ])
}

#' Find duplicate records
#' @param data Data frame
#' @param key_vars Optional vector of key variables
#' @return Data frame of duplicate records
find_duplicates <- function(data, key_vars = NULL) {
    if (is.null(key_vars)) {
        key_vars <- names(data)
    }

    duplicated_rows <- duplicated(data[, key_vars]) |
        duplicated(data[, key_vars], fromLast = TRUE)

    duplicates <- data[duplicated_rows, ]

    if (nrow(duplicates) > 0) {
        duplicates <- duplicates[order(duplicates[[key_vars[1]]]), ]
    }

    return(duplicates)
}

# Helper Functions --------------------------------------------------------

#' Clean dataset name for comparison
#' @param name Dataset name
#' @return Cleaned name (uppercase, trimmed)
clean_name <- function(name) {
    toupper(trimws(name))
}

#' Create summary statistics
#' @param data Data frame
#' @return Summary data frame
create_summary <- function(data) {
    summary_df <- data.frame(
        n_rows = nrow(data),
        n_cols = ncol(data),
        n_numeric = sum(sapply(data, is.numeric)),
        n_character = sum(sapply(data, is.character)),
        stringsAsFactors = FALSE
    )
    return(summary_df)
}
