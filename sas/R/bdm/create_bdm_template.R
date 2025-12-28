# ==============================================================================
# BDM Template Generator
# Script: create_bdm_template.R
# Purpose: Create customizable BDM template for manual mapping
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

cat("\n========================================\n")
cat("BDM Template Generator\n")
cat("========================================\n\n")

#' Create BDM Template for Custom Domain
#' @param source_file Source SAS dataset filename
#' @param target_domain Target SDTM/ADaM domain code
#' @param domain_description Domain description
create_bdm_template <- function(source_file, target_domain, domain_description) {
  
  cat(glue("Creating BDM template for {target_domain}...\n"))
  
  # Read source data
  source_path <- file.path(PATHS$raw_sas, source_file)
  
  if (!file.exists(source_path)) {
    stop(glue("Source file not found: {source_file}"))
  }
  
  source_data <- haven::read_sas(source_path)
  
  # Create template
  template <- tibble::tibble(
    `#` = 1:ncol(source_data),
    `Source Dataset` = source_file,
    `Source Variable` = names(source_data),
    `Source Label` = sapply(source_data, function(x) {
      label <- attr(x, "label")
      if (is.null(label) || label == "") names(source_data)[1] else label
    }),
    `Source Type` = sapply(source_data, function(x) class(x)[1]),
    
    `Target Domain` = target_domain,
    `Target Variable` = "",
    `Target Label` = "",
    `Target Type` = "",
    
    `Mapping Method` = "",
    `Derivation Logic` = "",
    `Controlled Terminology` = "",
    `Comments` = "",
    
    `Sample Values` = sapply(source_data, function(x) {
      vals <- unique(head(x[!is.na(x)], 3))
      paste(vals, collapse = "; ")
    })
  )
  
  # Add instruction sheet
  instructions <- tibble::tibble(
    Section = c(
      "Purpose",
      "Instructions",
      "Mapping Method",
      "Mapping Method",
      "Mapping Method",
      "Mapping Method",
      "Mapping Method",
      "Derivation Logic",
      "Controlled Terminology",
      "Review Process"
    ),
    Description = c(
      "This template is used to document the mapping from source data to SDTM/ADaM domains",
      "Fill in the Target Variable, Target Label, Target Type, Mapping Method, and Derivation Logic columns",
      "Direct - Direct copy from source to target",
      "Transform - Apply transformation (e.g., unit conversion, date format)",
      "Derive - Calculate/derive from multiple source variables",
      "Constant - Assign constant value",
      "Lookup - Use lookup table or controlled terminology",
      "Describe the specific algorithm or formula used for derivation",
      "Reference CDISC controlled terminology codelists where applicable",
      "Review and validate all mappings before implementation"
    )
  )
  
  # Create workbook
  template_file <- file.path(PATHS$bdm, glue("BDM_Template_{target_domain}.xlsx"))
  
  wb <- list(
    "Instructions" = instructions,
    "Mapping" = template,
    "Domain_Info" = tibble::tibble(
      Item = c("Target Domain", "Description", "Source File", "Total Variables", "Created Date"),
      Value = c(target_domain, domain_description, source_file, ncol(source_data), as.character(Sys.Date()))
    )
  )
  
  writexl::write_xlsx(wb, template_file)
  
  cat(glue("✓ Template saved: {basename(template_file)}\n\n"))
  
  return(template_file)
}

# ==============================================================================
# Example Usage
# ==============================================================================

cat("Example: Create BDM template for custom domain\n\n")
cat("Usage:\n")
cat("  create_bdm_template('your_file.sas7bdat', 'XX', 'Your Domain Description')\n\n")

cat("Available source files:\n")
sas_files <- list.files(PATHS$raw_sas, pattern = "\\.sas7bdat$")
for (i in seq_along(sas_files)) {
  cat(sprintf("  %2d. %s\n", i, sas_files[i]))
}

cat("\n========================================\n\n")
