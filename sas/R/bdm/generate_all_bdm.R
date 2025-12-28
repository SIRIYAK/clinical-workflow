# ==============================================================================
# BDM (Blank Data Mapping) Specification Generator
# Script: generate_all_bdm.R
# Purpose: Generate comprehensive BDM specifications for all domains
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

init_log("generate_all_bdm")

cat("\n========================================\n")
cat("BDM Specification Generator\n")
cat("========================================\n\n")

log_message("Starting BDM specification generation for all domains...")

# ==============================================================================
# Enhanced BDM Generation Function
# ==============================================================================

generate_enhanced_bdm <- function(source_file, target_domain, domain_name) {
  
  log_message(glue("Generating BDM for {target_domain}..."))
  
  # Read source data
  source_path <- file.path(PATHS$raw_sas, source_file)
  
  if (!file.exists(source_path)) {
    log_message(glue("WARNING: Source file not found: {source_file}"), level = "WARN")
    return(NULL)
  }
  
  source_data <- haven::read_sas(source_path)
  
  # Get variable metadata
  var_labels <- sapply(source_data, function(x) attr(x, "label"))
  var_types <- sapply(source_data, function(x) class(x)[1])
  var_formats <- sapply(source_data, function(x) attr(x, "format.sas"))
  
  # Create BDM specification
  bdm <- tibble::tibble(
    Row_Number = 1:ncol(source_data),
    Source_Dataset = source_file,
    Source_Variable = names(source_data),
    Source_Label = ifelse(is.null(var_labels) | var_labels == "", 
                          Source_Variable, 
                          var_labels),
    Source_Type = var_types,
    Source_Format = ifelse(is.null(var_formats), "", var_formats),
    Source_Length = sapply(source_data, function(x) {
      if (is.character(x)) max(nchar(x), na.rm = TRUE) else NA
    }),
    
    Target_Domain = target_domain,
    Target_Variable = "",
    Target_Label = "",
    Target_Type = "",
    Target_Length = "",
    
    Mapping_Logic = "",
    Derivation_Algorithm = "",
    Controlled_Terminology = "",
    Codelist_Reference = "",
    
    Required = "",
    Core = "",
    Comments = "",
    
    Sample_Values = sapply(source_data, function(x) {
      vals <- unique(head(x[!is.na(x)], 3))
      paste(vals, collapse = "; ")
    }),
    
    Missing_Count = sapply(source_data, function(x) sum(is.na(x))),
    Missing_Percent = round(sapply(source_data, function(x) sum(is.na(x)) / length(x) * 100), 2)
  )
  
  # Add suggested SDTM mappings based on variable names
  bdm <- bdm %>%
    dplyr::mutate(
      Target_Variable = dplyr::case_when(
        # Common identifiers
        stringr::str_detect(Source_Variable, "(?i)SUBJID|SUBJECT") ~ "SUBJID",
        stringr::str_detect(Source_Variable, "(?i)SITE") ~ "SITEID",
        stringr::str_detect(Source_Variable, "(?i)VISIT") ~ "VISIT",
        
        # Demographics
        stringr::str_detect(Source_Variable, "(?i)AGE") ~ "AGE",
        stringr::str_detect(Source_Variable, "(?i)SEX|GENDER") ~ "SEX",
        stringr::str_detect(Source_Variable, "(?i)RACE") ~ "RACE",
        stringr::str_detect(Source_Variable, "(?i)ETHNIC") ~ "ETHNIC",
        
        # Dates
        stringr::str_detect(Source_Variable, "(?i)STDT|START.*DATE") ~ paste0(target_domain, "STDTC"),
        stringr::str_detect(Source_Variable, "(?i)ENDT|END.*DATE") ~ paste0(target_domain, "ENDTC"),
        
        # Test results
        stringr::str_detect(Source_Variable, "(?i)TEST") ~ paste0(target_domain, "TEST"),
        stringr::str_detect(Source_Variable, "(?i)RESULT|ORRES") ~ paste0(target_domain, "ORRES"),
        
        TRUE ~ ""
      ),
      
      Mapping_Logic = dplyr::case_when(
        Target_Variable != "" ~ "Direct mapping",
        TRUE ~ "To be determined"
      ),
      
      Required = dplyr::case_when(
        Target_Variable %in% c("STUDYID", "DOMAIN", "USUBJID") ~ "Yes",
        stringr::str_detect(Target_Variable, "SEQ$") ~ "Yes",
        TRUE ~ "No"
      ),
      
      Core = dplyr::case_when(
        Required == "Yes" ~ "Req",
        Target_Variable != "" ~ "Exp",
        TRUE ~ "Perm"
      )
    )
  
  # Export to Excel with multiple sheets
  bdm_file <- file.path(PATHS$bdm, glue("BDM_{target_domain}_{domain_name}.xlsx"))
  
  # Create workbook
  wb <- list(
    "Mapping_Specification" = bdm,
    "Domain_Summary" = tibble::tibble(
      Domain = target_domain,
      Domain_Name = domain_name,
      Source_File = source_file,
      Total_Variables = nrow(bdm),
      Mapped_Variables = sum(bdm$Target_Variable != ""),
      Unmapped_Variables = sum(bdm$Target_Variable == ""),
      Required_Variables = sum(bdm$Required == "Yes"),
      Total_Records = nrow(source_data),
      Generation_Date = as.character(Sys.Date()),
      Generated_By = "SDTM/ADaM Automation Framework"
    ),
    "Controlled_Terminology" = tibble::tibble(
      Variable = character(),
      Codelist = character(),
      Permitted_Values = character(),
      Reference = character()
    )
  )
  
  writexl::write_xlsx(wb, bdm_file)
  
  log_message(glue("✓ BDM saved: {basename(bdm_file)}"))
  
  return(bdm)
}

# ==============================================================================
# Generate BDM for All SDTM Domains
# ==============================================================================

cat("\n[Phase 1] Generating SDTM BDM Specifications\n")
cat("========================================\n\n")

sdtm_bdm_list <- list()

# DM - Demographics
sdtm_bdm_list$dm <- generate_enhanced_bdm("dmgen.sas7bdat", "DM", "Demographics")

# AE - Adverse Events
sdtm_bdm_list$ae <- generate_enhanced_bdm("aesae.sas7bdat", "AE", "Adverse Events")

# VS - Vital Signs
sdtm_bdm_list$vs <- generate_enhanced_bdm("vsgen.sas7bdat", "VS", "Vital Signs")

# LB - Laboratory
sdtm_bdm_list$lb <- generate_enhanced_bdm("lblocal.sas7bdat", "LB", "Laboratory")

# CM - Concomitant Medications
sdtm_bdm_list$cm <- generate_enhanced_bdm("cmgen.sas7bdat", "CM", "Concomitant Medications")

# EG - ECG
sdtm_bdm_list$eg <- generate_enhanced_bdm("eggen.sas7bdat", "EG", "ECG Test Results")

# EX - Exposure
sdtm_bdm_list$ex <- generate_enhanced_bdm("ecgen.sas7bdat", "EX", "Exposure")

# DS - Disposition
sdtm_bdm_list$ds <- generate_enhanced_bdm("dsic.sas7bdat", "DS", "Disposition")

# MH - Medical History
sdtm_bdm_list$mh <- generate_enhanced_bdm("mhgen.sas7bdat", "MH", "Medical History")

# SU - Substance Use
sdtm_bdm_list$su <- generate_enhanced_bdm("sugen.sas7bdat", "SU", "Substance Use")

# ==============================================================================
# Generate Master BDM Index
# ==============================================================================

cat("\n[Phase 2] Generating Master BDM Index\n")
cat("========================================\n\n")

log_message("Creating master BDM index...")

master_index <- tibble::tibble(
  Domain = character(),
  Domain_Name = character(),
  Source_File = character(),
  Total_Variables = integer(),
  Mapped_Variables = integer(),
  Mapping_Percent = numeric(),
  BDM_File = character()
)

for (domain in names(sdtm_bdm_list)) {
  if (!is.null(sdtm_bdm_list[[domain]])) {
    bdm <- sdtm_bdm_list[[domain]]
    master_index <- master_index %>%
      dplyr::bind_rows(
        tibble::tibble(
          Domain = toupper(domain),
          Domain_Name = unique(bdm$Target_Domain)[1],
          Source_File = unique(bdm$Source_Dataset)[1],
          Total_Variables = nrow(bdm),
          Mapped_Variables = sum(bdm$Target_Variable != ""),
          Mapping_Percent = round(sum(bdm$Target_Variable != "") / nrow(bdm) * 100, 1),
          BDM_File = glue("BDM_{toupper(domain)}_{gsub(' ', '_', unique(bdm$Target_Domain)[1])}.xlsx")
        )
      )
  }
}

# Export master index
master_file <- file.path(PATHS$bdm, "BDM_Master_Index.xlsx")

master_wb <- list(
  "BDM_Index" = master_index,
  "Generation_Info" = tibble::tibble(
    Item = c("Generation Date", "Total Domains", "Total Source Files", 
             "Total Variables", "Framework Version"),
    Value = c(as.character(Sys.Date()), 
              nrow(master_index),
              length(unique(master_index$Source_File)),
              sum(master_index$Total_Variables),
              "1.0.0")
  )
)

writexl::write_xlsx(master_wb, master_file)

log_message(glue("✓ Master BDM index saved: {basename(master_file)}"))

# ==============================================================================
# Summary
# ==============================================================================

cat("\n========================================\n")
cat("BDM Generation Summary\n")
cat("========================================\n\n")

cat("SDTM Domains:\n")
cat(strrep("-", 80), "\n")
cat(sprintf("%-10s %-30s %-15s %s\n", "Domain", "Name", "Variables", "Mapped %"))
cat(strrep("-", 80), "\n")

for (i in 1:nrow(master_index)) {
  cat(sprintf("%-10s %-30s %-15d %.1f%%\n", 
              master_index$Domain[i],
              master_index$Domain_Name[i],
              master_index$Total_Variables[i],
              master_index$Mapping_Percent[i]))
}

cat(strrep("-", 80), "\n")
cat(sprintf("%-10s %-30s %-15d\n", 
            "TOTAL", 
            paste(nrow(master_index), "domains"),
            sum(master_index$Total_Variables)))
cat(strrep("-", 80), "\n\n")

cat("BDM Files Generated:\n")
cat(strrep("-", 80), "\n")
bdm_files <- list.files(PATHS$bdm, pattern = "\\.xlsx$", full.names = FALSE)
for (file in bdm_files) {
  file_size <- file.size(file.path(PATHS$bdm, file))
  cat(sprintf("  %-60s %10.2f KB\n", file, file_size / 1024))
}
cat(strrep("-", 80), "\n\n")

cat("✓ All BDM specifications generated successfully!\n")
cat("  Location: specs/bdm/\n\n")

close_log()
