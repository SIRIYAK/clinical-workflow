# =============================================================================
# Preprocessing Functions for Data Validation
# Author: Siriyak
# Date: 2026-01-14
# Description: Preprocessing steps including data loading, environment setup,
#              and initial validation setup
# =============================================================================

# Source required files ---------------------------------------------------
source("config.R")
source("utils.R")

# Preprocessing Functions -------------------------------------------------

#' Initialize validation environment
#' @return List containing initialization status
initialize_validation_env <- function() {
    log_section("PREPROCESSING: Initializing Validation Environment")

    # Print configuration
    print_config()

    # Check if output directory exists, create if needed
    if (!dir.exists(OUT_PATH)) {
        message("Creating output directory...")
        dir.create(OUT_PATH, recursive = TRUE, showWarnings = FALSE)
    }

    # Initialize results list
    results <- list(
        session_id = SESSION_ID,
        start_time = SESSION_START,
        status = "initialized"
    )

    log_message("Validation environment initialized successfully")

    return(results)
}

#' Load CDB library datasets
#' @return List of CDB datasets with cdb_ prefix
load_cdb_library <- function() {
    log_section("PREPROCESSING: Loading CDB Library")

    log_message(paste("Loading datasets from:", CDB_LIB_PATH))

    # Read all datasets
    cdb_datasets <- read_library(CDB_LIB_PATH)

    # Add cdb_ prefix to names
    names(cdb_datasets) <- paste0("cdb_", tolower(names(cdb_datasets)))

    log_message(paste("Loaded", length(cdb_datasets), "CDB datasets"))

    return(cdb_datasets)
}

#' Load ALSC library datasets
#' @return List of ALSC datasets with inf_ prefix
load_alsc_library <- function() {
    log_section("PREPROCESSING: Loading ALSC Library")

    log_message(paste("Loading datasets from:", ALSC_LIB_PATH))

    # Read all datasets
    alsc_datasets <- read_library(ALSC_LIB_PATH)

    # Add inf_ prefix to names
    names(alsc_datasets) <- paste0("inf_", tolower(names(alsc_datasets)))

    log_message(paste("Loaded", length(alsc_datasets), "ALSC datasets"))

    return(alsc_datasets)
}

#' Prepare comparison metadata
#' @param cdb_list List of CDB datasets
#' @param alsc_list List of ALSC datasets
#' @return List containing metadata for comparison
prepare_comparison_metadata <- function(cdb_list, alsc_list) {
    log_section("PREPROCESSING: Preparing Comparison Metadata")

    # Get dataset names (remove prefixes for comparison)
    cdb_names <- gsub("^cdb_", "", names(cdb_list))
    alsc_names <- gsub("^inf_", "", names(alsc_list))

    # Create metadata data frames
    ds_cdb <- data.frame(
        memname = cdb_names,
        stringsAsFactors = FALSE
    )

    ds_alsc <- data.frame(
        memname = alsc_names,
        stringsAsFactors = FALSE
    )

    # Find common and missing datasets
    common_ds <- find_common_datasets(alsc_names, cdb_names)
    ds_not_in_cdb <- find_missing_datasets(alsc_names, cdb_names)
    ds_not_in_alsc <- find_missing_datasets(cdb_names, alsc_names)

    # Create summary
    log_message(paste("Total CDB datasets:", nrow(ds_cdb)))
    log_message(paste("Total ALSC datasets:", nrow(ds_alsc)))
    log_message(paste("Common datasets:", length(common_ds)))
    log_message(paste("Datasets only in ALSC:", length(ds_not_in_cdb)))
    log_message(paste("Datasets only in CDB:", length(ds_not_in_alsc)))

    metadata <- list(
        ds_cdb = ds_cdb,
        ds_alsc = ds_alsc,
        common_ds = common_ds,
        ds_not_in_cdb = data.frame(memname = ds_not_in_cdb, stringsAsFactors = FALSE),
        ds_not_in_alsc = data.frame(memname = ds_not_in_alsc, stringsAsFactors = FALSE),
        total_cds = length(common_ds)
    )

    return(metadata)
}

#' Extract variable metadata for all datasets
#' @param dataset_list Named list of datasets
#' @param prefix Prefix to identify dataset source
#' @return Data frame with all variable metadata
extract_all_metadata <- function(dataset_list, prefix = "") {
    log_message(paste("Extracting metadata for", length(dataset_list), "datasets"))

    all_metadata <- lapply(names(dataset_list), function(ds_name) {
        get_dataset_metadata(dataset_list[[ds_name]], ds_name)
    })

    # Combine all metadata
    combined_metadata <- do.call(rbind, all_metadata)

    return(combined_metadata)
}

#' Create observation summary for datasets
#' @param dataset_list Named list of datasets
#' @return Data frame with observation counts
create_obs_summary <- function(dataset_list) {
    obs_summary <- data.frame(
        memname = names(dataset_list),
        nobs = sapply(dataset_list, nrow),
        stringsAsFactors = FALSE
    )

    return(obs_summary)
}

#' Validate prerequisites
#' @return TRUE if all prerequisites are met, error otherwise
validate_prerequisites <- function() {
    log_section("PREPROCESSING: Validating Prerequisites")

    errors <- character()

    # Check if CDB library path exists (or can be accessed)
    # Note: This might fail on Linux paths from Windows, so we'll just warn
    if (!dir.exists(CDB_LIB_PATH)) {
        warning(paste("CDB library path not accessible:", CDB_LIB_PATH))
        warning("This may be normal if running in a different environment")
    }

    # Check if ALSC library path exists
    if (!dir.exists(ALSC_LIB_PATH)) {
        warning(paste("ALSC library path not accessible:", ALSC_LIB_PATH))
        warning("This may be normal if running in a different environment")
    }

    # Check required packages
    required_packages <- c("haven", "openxlsx", "dplyr", "tidyr", "purrr")

    for (pkg in required_packages) {
        if (!requireNamespace(pkg, quietly = TRUE)) {
            errors <- c(errors, paste("Required package not installed:", pkg))
        }
    }

    if (length(errors) > 0) {
        stop(paste(
            "Prerequisites validation failed:\n",
            paste(errors, collapse = "\n")
        ))
    }

    log_message("All prerequisites validated successfully")
    return(TRUE)
}

#' Main preprocessing function
#' @return List containing all preprocessing results
run_preprocessing <- function() {
    log_section("STARTING PREPROCESSING PHASE")

    # Validate prerequisites
    validate_prerequisites()

    # Initialize environment
    init_results <- initialize_validation_env()

    # Load libraries
    # Note: In production, these would load from actual paths
    # For now, we'll handle gracefully if paths don't exist

    cdb_list <- tryCatch(
        {
            load_cdb_library()
        },
        error = function(e) {
            warning("Could not load CDB library: ", e$message)
            warning("Using empty dataset list for demonstration")
            list()
        }
    )

    alsc_list <- tryCatch(
        {
            load_alsc_library()
        },
        error = function(e) {
            warning("Could not load ALSC library: ", e$message)
            warning("Using empty dataset list for demonstration")
            list()
        }
    )

    # Prepare metadata if we have data
    if (length(cdb_list) > 0 && length(alsc_list) > 0) {
        metadata <- prepare_comparison_metadata(cdb_list, alsc_list)
    } else {
        metadata <- list(
            ds_cdb = data.frame(),
            ds_alsc = data.frame(),
            common_ds = character(),
            ds_not_in_cdb = data.frame(),
            ds_not_in_alsc = data.frame(),
            total_cds = 0
        )
    }

    log_section("PREPROCESSING PHASE COMPLETED")

    # Return all preprocessing results
    return(list(
        init_results = init_results,
        cdb_datasets = cdb_list,
        alsc_datasets = alsc_list,
        metadata = metadata
    ))
}
