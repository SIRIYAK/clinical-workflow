# ==============================================================================
# SDTM/ADaM/BDM Automation Framework
# Script: 02_utilities.R
# Purpose: Utility functions for data processing, validation, and export
# ==============================================================================

# ==============================================================================
# 1. Data Reading Functions
# ==============================================================================

#' Read SAS Dataset with Metadata
#' @param file_name Name of SAS file (e.g., "dmgen.sas7bdat")
#' @param path Path to directory containing SAS files
#' @return Tibble with data and attributes
read_sas_data <- function(file_name, path = PATHS$raw_sas) {
  file_path <- file.path(path, file_name)
  
  if (!file.exists(file_path)) {
    stop(glue("File not found: {file_path}"))
  }
  
  log_message(glue("Reading: {file_name}"))
  
  data <- haven::read_sas(file_path) %>%
    tibble::as_tibble() %>%
    janitor::clean_names(case = "upper_camel")  # Convert to proper case
  
  log_message(glue("  Records: {nrow(data)}, Variables: {ncol(data)}"))
  
  return(data)
}

#' Read Multiple SAS Datasets and Combine
#' @param file_names Vector of SAS file names
#' @param path Path to directory containing SAS files
#' @return Combined tibble
read_and_combine_sas <- function(file_names, path = PATHS$raw_sas) {
  datasets <- purrr::map(file_names, ~read_sas_data(.x, path))
  
  # Combine datasets
  combined <- dplyr::bind_rows(datasets)
  
  log_message(glue("Combined {length(file_names)} datasets: {nrow(combined)} total records"))
  
  return(combined)
}

# ==============================================================================
# 2. SDTM Derivation Functions
# ==============================================================================

#' Create USUBJID from SUBJID
#' @param data Data frame with SUBJID
#' @param study_id Study identifier
#' @return Data frame with USUBJID
derive_usubjid <- function(data, study_id = STUDY_CONFIG$study_id) {
  data %>%
    dplyr::mutate(
      STUDYID = study_id,
      USUBJID = paste(STUDYID, SUBJID, sep = "-")
    )
}

#' Derive Study Day
#' @param data Data frame with date variable
#' @param date_var Name of date variable
#' @param ref_date_var Name of reference date variable (e.g., RFSTDTC from DM)
#' @return Data frame with study day variable
derive_study_day <- function(data, date_var, ref_date_var = "RFSTDTC") {
  dy_var <- stringr::str_replace(date_var, "DTC$", "DY")
  
  data %>%
    dplyr::mutate(
      !!dy_var := dplyr::case_when(
        is.na(!!sym(date_var)) ~ NA_real_,
        !!sym(date_var) >= !!sym(ref_date_var) ~ 
          as.numeric(difftime(!!sym(date_var), !!sym(ref_date_var), units = "days")) + 1,
        TRUE ~ 
          as.numeric(difftime(!!sym(date_var), !!sym(ref_date_var), units = "days"))
      )
    )
}

#' Apply CDISC Controlled Terminology
#' @param data Data frame
#' @param var Variable name
#' @param ct_list Controlled terminology list
#' @return Data frame with standardized values
apply_ct <- function(data, var, ct_list) {
  data %>%
    dplyr::mutate(
      !!var := dplyr::recode(!!sym(var), !!!ct_list)
    )
}

#' Derive Sequence Number
#' @param data Data frame
#' @param seq_var Name of sequence variable to create
#' @param by_vars Grouping variables
#' @return Data frame with sequence number
derive_seq <- function(data, seq_var, by_vars = c("STUDYID", "USUBJID")) {
  data %>%
    dplyr::group_by(across(all_of(by_vars))) %>%
    dplyr::mutate(!!seq_var := row_number()) %>%
    dplyr::ungroup()
}

# ==============================================================================
# 3. Data Validation Functions
# ==============================================================================

#' Validate Required Variables
#' @param data Data frame
#' @param required_vars Vector of required variable names
#' @param domain_name Domain name for logging
#' @return Validation results
validate_required_vars <- function(data, required_vars, domain_name) {
  missing_vars <- setdiff(required_vars, names(data))
  
  if (length(missing_vars) > 0) {
    log_message(glue("WARNING: {domain_name} missing required variables: {paste(missing_vars, collapse=', ')}"), 
                level = "WARN")
    return(FALSE)
  }
  
  log_message(glue("✓ {domain_name}: All required variables present"))
  return(TRUE)
}

#' Validate Data Types
#' @param data Data frame
#' @param type_spec Named list of variable types
#' @param domain_name Domain name for logging
#' @return Validation results
validate_data_types <- function(data, type_spec, domain_name) {
  issues <- c()
  
  for (var in names(type_spec)) {
    if (var %in% names(data)) {
      expected_type <- type_spec[[var]]
      actual_type <- class(data[[var]])[1]
      
      if (expected_type == "character" && !is.character(data[[var]])) {
        issues <- c(issues, glue("{var}: expected character, got {actual_type}"))
      } else if (expected_type == "numeric" && !is.numeric(data[[var]])) {
        issues <- c(issues, glue("{var}: expected numeric, got {actual_type}"))
      } else if (expected_type == "date" && !lubridate::is.Date(data[[var]])) {
        issues <- c(issues, glue("{var}: expected date, got {actual_type}"))
      }
    }
  }
  
  if (length(issues) > 0) {
    log_message(glue("WARNING: {domain_name} data type issues:\n  {paste(issues, collapse='\n  ')}"), 
                level = "WARN")
    return(FALSE)
  }
  
  log_message(glue("✓ {domain_name}: All data types correct"))
  return(TRUE)
}

#' Check for Duplicate Records
#' @param data Data frame
#' @param key_vars Key variables that should be unique
#' @param domain_name Domain name for logging
#' @return Validation results
check_duplicates <- function(data, key_vars, domain_name) {
  dup_count <- data %>%
    dplyr::group_by(across(all_of(key_vars))) %>%
    dplyr::filter(n() > 1) %>%
    dplyr::ungroup() %>%
    nrow()
  
  if (dup_count > 0) {
    log_message(glue("WARNING: {domain_name} has {dup_count} duplicate records based on key variables"), 
                level = "WARN")
    return(FALSE)
  }
  
  log_message(glue("✓ {domain_name}: No duplicate records"))
  return(TRUE)
}

# ==============================================================================
# 4. Export Functions
# ==============================================================================

#' Export Dataset to Multiple Formats
#' @param data Data frame to export
#' @param domain_name Domain name (e.g., "dm", "ae")
#' @param dataset_type "sdtm" or "adam"
#' @param label Dataset label
#' @return TRUE if successful
export_dataset <- function(data, domain_name, dataset_type = "sdtm", label = NULL) {
  
  # Determine output path
  output_path <- if (dataset_type == "sdtm") PATHS$sdtm else PATHS$adam
  
  # Convert domain name to uppercase
  domain_upper <- toupper(domain_name)
  
  log_message(glue("Exporting {domain_upper} ({nrow(data)} records)..."))
  
  # 1. Export as SAS7BDAT
  if (EXPORT_CONFIG$export_sas) {
    sas_file <- file.path(output_path, glue("{tolower(domain_name)}.sas7bdat"))
    haven::write_sas(data, sas_file)
    log_message(glue("  ✓ Saved: {basename(sas_file)}"))
  }
  
  # 2. Export as XPT (SAS Transport v5)
  xpt_file <- file.path(output_path, glue("{tolower(domain_name)}.xpt"))
  
  # Apply dataset label if provided
  if (!is.null(label)) {
    attr(data, "label") <- label
  }
  
  # Use xportr to create XPT file
  data %>%
    xportr::xportr_write(xpt_file, label = label)
  
  log_message(glue("  ✓ Saved: {basename(xpt_file)}"))
  
  # 3. Export as CSV (optional)
  if (EXPORT_CONFIG$export_csv) {
    csv_file <- file.path(output_path, glue("{tolower(domain_name)}.csv"))
    readr::write_csv(data, csv_file, na = "")
    log_message(glue("  ✓ Saved: {basename(csv_file)}"))
  }
  
  return(TRUE)
}

# ==============================================================================
# 5. Logging Functions
# ==============================================================================

#' Initialize Log File
#' @param script_name Name of script being executed
#' @return Log file path
init_log <- function(script_name) {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  log_file <- file.path(PATHS$logs, glue("{script_name}_{timestamp}.log"))
  
  # Create log file
  cat(glue("========================================\n"), file = log_file)
  cat(glue("Log: {script_name}\n"), file = log_file, append = TRUE)
  cat(glue("Started: {Sys.time()}\n"), file = log_file, append = TRUE)
  cat(glue("========================================\n\n"), file = log_file, append = TRUE)
  
  # Store log file path in global environment
  assign("CURRENT_LOG_FILE", log_file, envir = .GlobalEnv)
  
  return(log_file)
}

#' Log Message
#' @param message Message to log
#' @param level Log level (DEBUG, INFO, WARN, ERROR)
log_message <- function(message, level = "INFO") {
  timestamp <- format(Sys.time(), LOG_CONFIG$timestamp_format)
  log_entry <- glue("[{timestamp}] [{level}] {message}")
  
  # Print to console if enabled
  if (LOG_CONFIG$log_to_console) {
    cat(log_entry, "\n")
  }
  
  # Write to log file if enabled and log file exists
  if (LOG_CONFIG$log_to_file && exists("CURRENT_LOG_FILE", envir = .GlobalEnv)) {
    cat(log_entry, "\n", file = get("CURRENT_LOG_FILE", envir = .GlobalEnv), append = TRUE)
  }
}

#' Close Log File
close_log <- function() {
  if (exists("CURRENT_LOG_FILE", envir = .GlobalEnv)) {
    log_file <- get("CURRENT_LOG_FILE", envir = .GlobalEnv)
    cat(glue("\n========================================\n"), file = log_file, append = TRUE)
    cat(glue("Completed: {Sys.time()}\n"), file = log_file, append = TRUE)
    cat(glue("========================================\n"), file = log_file, append = TRUE)
  }
}

# ==============================================================================
# 6. BDM Generation Functions
# ==============================================================================

#' Generate Blank Data Mapping Specification
#' @param source_data Source data frame
#' @param target_domain Target SDTM/ADaM domain name
#' @param mapping_list Named list of source -> target variable mappings
#' @return BDM specification data frame
generate_bdm_spec <- function(source_data, target_domain, mapping_list) {
  
  bdm_spec <- tibble::tibble(
    Source_Dataset = deparse(substitute(source_data)),
    Source_Variable = names(source_data),
    Source_Type = sapply(source_data, function(x) class(x)[1]),
    Target_Domain = target_domain,
    Target_Variable = NA_character_,
    Mapping_Logic = NA_character_,
    Controlled_Terminology = NA_character_,
    Comments = NA_character_
  )
  
  # Apply mappings
  for (source_var in names(mapping_list)) {
    target_var <- mapping_list[[source_var]]
    bdm_spec <- bdm_spec %>%
      dplyr::mutate(
        Target_Variable = dplyr::if_else(Source_Variable == source_var, target_var, Target_Variable),
        Mapping_Logic = dplyr::if_else(Source_Variable == source_var, "Direct mapping", Mapping_Logic)
      )
  }
  
  return(bdm_spec)
}

#' Export BDM Specification to Excel
#' @param bdm_spec BDM specification data frame
#' @param domain_name Domain name
#' @return TRUE if successful
export_bdm <- function(bdm_spec, domain_name) {
  bdm_file <- file.path(PATHS$bdm, glue("BDM_{toupper(domain_name)}.xlsx"))
  
  writexl::write_xlsx(bdm_spec, bdm_file)
  
  log_message(glue("✓ BDM specification saved: {basename(bdm_file)}"))
  
  return(TRUE)
}

# ==============================================================================
# 7. Helper Functions
# ==============================================================================

#' Convert Date to ISO 8601 Format
#' @param date_var Date variable
#' @return Character vector in ISO 8601 format (YYYY-MM-DD)
format_iso_date <- function(date_var) {
  format(date_var, "%Y-%m-%d")
}

#' Convert DateTime to ISO 8601 Format
#' @param datetime_var DateTime variable
#' @return Character vector in ISO 8601 format (YYYY-MM-DDTHH:MM:SS)
format_iso_datetime <- function(datetime_var) {
  format(datetime_var, "%Y-%m-%dT%H:%M:%S")
}

#' Create Domain Template
#' @param domain_name Domain name
#' @param key_vars Key variables for the domain
#' @return Empty data frame with standard structure
create_domain_template <- function(domain_name, key_vars) {
  template <- tibble::tibble(
    STUDYID = character(),
    DOMAIN = character(),
    USUBJID = character()
  )
  
  # Add key variables
  for (var in key_vars) {
    if (!var %in% names(template)) {
      template[[var]] <- character()
    }
  }
  
  # Set DOMAIN value
  template$DOMAIN <- toupper(domain_name)
  
  return(template)
}

cat("\n✓ Utility functions loaded successfully\n\n")
