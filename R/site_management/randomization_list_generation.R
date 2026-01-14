# ==============================================================================
# Randomization List Generation & Validation
# Script: randomization_list_generation.R
# Purpose: Generate validated randomization lists and sealed envelopes
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/biostat/study_design/randomization_utilities.R")

library(dplyr)
library(glue)
library(officer)

cat("\n========================================\n")
cat("Randomization List Generation\n")
cat("========================================\n\n")

# ==============================================================================
# 1. Generate Master Randomization List
# ==============================================================================

generate_master_randomization_list <- function(
  n_subjects,
  treatments,
  allocation_ratio = NULL,
  randomization_type = "block",
  block_size = 4,
  stratification_factors = NULL,
  seed = NULL,
  study_id = "STUDY-001",
  generated_by = "Independent Statistician"
) {
  
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          MASTER RANDOMIZATION LIST GENERATION                  ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  # Set seed for reproducibility
  if (!is.null(seed)) {
    set.seed(seed)
    cat(glue("Random seed: {seed}\n"))
  } else {
    seed <- as.integer(Sys.time())
    set.seed(seed)
    cat(glue("Random seed (auto-generated): {seed}\n"))
  }
  
  # Default allocation ratio (equal)
  if (is.null(allocation_ratio)) {
    allocation_ratio <- rep(1, length(treatments))
  }
  
  cat(glue("\nRandomization Parameters:\n"))
  cat(glue("  Total subjects: {n_subjects}\n"))
  cat(glue("  Treatments: {paste(treatments, collapse = ', ')}\n"))
  cat(glue("  Allocation ratio: {paste(allocation_ratio, collapse = ':')}\n"))
  cat(glue("  Randomization type: {randomization_type}\n"))
  if (randomization_type == "block") {
    cat(glue("  Block size: {block_size}\n"))
  }
  cat("\n")
  
  # Generate randomization based on type
  if (randomization_type == "simple") {
    # Simple randomization
    randomization_list <- simple_randomization(
      n = n_subjects,
      treatments = treatments,
      allocation_ratio = allocation_ratio
    )
    
  } else if (randomization_type == "block") {
    # Block randomization
    randomization_list <- block_randomization(
      n = n_subjects,
      treatments = treatments,
      block_size = block_size,
      allocation_ratio = allocation_ratio
    )
    
  } else if (randomization_type == "stratified") {
    # Stratified randomization (requires stratification factors)
    if (is.null(stratification_factors)) {
      stop("Stratification factors required for stratified randomization")
    }
    
    randomization_list <- stratified_randomization(
      n = n_subjects,
      treatments = treatments,
      strata = stratification_factors,
      block_size = block_size
    )
    
  } else {
    stop("Unknown randomization type. Use 'simple', 'block', or 'stratified'")
  }
  
  # Add randomization numbers
  randomization_list <- randomization_list %>%
    mutate(
      Randomization_Number = sprintf("RAND-%04d", row_number()),
      Study_ID = study_id,
      Generated_Date = Sys.Date(),
      Generated_By = generated_by,
      Random_Seed = seed
    ) %>%
    select(Randomization_Number, Study_ID, Treatment, Block, 
           Generated_Date, Generated_By, Random_Seed)
  
  cat("✓ Master randomization list generated\n")
  cat(glue("  Total allocations: {nrow(randomization_list)}\n\n"))
  
  # Treatment allocation summary
  allocation_summary <- randomization_list %>%
    count(Treatment, name = "N") %>%
    mutate(Percentage = round(N / sum(N) * 100, 1))
  
  cat("Treatment Allocation:\n")
  print(allocation_summary)
  cat("\n")
  
  return(randomization_list)
}

# ==============================================================================
# 2. Validate Randomization List
# ==============================================================================

validate_randomization_list <- function(randomization_list, 
                                       expected_allocation_ratio = NULL,
                                       block_size = NULL) {
  
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          RANDOMIZATION LIST VALIDATION                         ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  validation_results <- list()
  all_checks_passed <- TRUE
  
  # Check 1: Unique randomization numbers
  cat("Check 1: Unique randomization numbers...\n")
  n_unique <- n_distinct(randomization_list$Randomization_Number)
  n_total <- nrow(randomization_list)
  
  if (n_unique == n_total) {
    cat("  ✓ PASS: All randomization numbers are unique\n\n")
    validation_results$unique_numbers <- "PASS"
  } else {
    cat(glue("  ✗ FAIL: Found {n_total - n_unique} duplicate randomization numbers\n\n"))
    validation_results$unique_numbers <- "FAIL"
    all_checks_passed <- FALSE
  }
  
  # Check 2: Treatment allocation balance
  cat("Check 2: Treatment allocation balance...\n")
  allocation_summary <- randomization_list %>%
    count(Treatment, name = "N") %>%
    mutate(Percentage = round(N / sum(N) * 100, 1))
  
  print(allocation_summary)
  
  if (!is.null(expected_allocation_ratio)) {
    expected_percentages <- expected_allocation_ratio / sum(expected_allocation_ratio) * 100
    actual_percentages <- allocation_summary$Percentage
    
    # Allow 5% deviation
    if (all(abs(actual_percentages - expected_percentages) < 5)) {
      cat("  ✓ PASS: Allocation ratios within acceptable range\n\n")
      validation_results$allocation_balance <- "PASS"
    } else {
      cat("  ⚠ WARNING: Allocation ratios deviate from expected\n\n")
      validation_results$allocation_balance <- "WARNING"
    }
  } else {
    cat("  ✓ PASS: Allocation summary generated\n\n")
    validation_results$allocation_balance <- "PASS"
  }
  
  # Check 3: Block integrity (if applicable)
  if (!is.null(block_size) && "Block" %in% names(randomization_list)) {
    cat("Check 3: Block integrity...\n")
    
    block_check <- randomization_list %>%
      group_by(Block) %>%
      summarise(
        Block_Size = n(),
        .groups = "drop"
      )
    
    if (all(block_check$Block_Size == block_size | 
            block_check$Block_Size < block_size & block_check$Block == max(block_check$Block))) {
      cat(glue("  ✓ PASS: All blocks have size {block_size} (except possibly last block)\n\n"))
      validation_results$block_integrity <- "PASS"
    } else {
      cat("  ✗ FAIL: Block sizes are inconsistent\n\n")
      validation_results$block_integrity <- "FAIL"
      all_checks_passed <- FALSE
    }
  }
  
  # Check 4: No missing values
  cat("Check 4: Missing values...\n")
  missing_treatment <- sum(is.na(randomization_list$Treatment))
  missing_rand_num <- sum(is.na(randomization_list$Randomization_Number))
  
  if (missing_treatment == 0 && missing_rand_num == 0) {
    cat("  ✓ PASS: No missing values\n\n")
    validation_results$missing_values <- "PASS"
  } else {
    cat(glue("  ✗ FAIL: Found {missing_treatment} missing treatments, {missing_rand_num} missing numbers\n\n"))
    validation_results$missing_values <- "FAIL"
    all_checks_passed <- FALSE
  }
  
  # Overall validation result
  cat("════════════════════════════════════════════════════════════════\n")
  if (all_checks_passed) {
    cat("✓ VALIDATION PASSED: Randomization list is valid\n")
    validation_results$overall <- "PASS"
  } else {
    cat("✗ VALIDATION FAILED: Please review failed checks\n")
    validation_results$overall <- "FAIL"
  }
  cat("════════════════════════════════════════════════════════════════\n\n")
  
  # Save validation report
  validation_report <- tibble(
    Check = names(validation_results),
    Result = unlist(validation_results)
  )
  
  writexl::write_xlsx(validation_report, "outputs/Randomization_Validation_Report.xlsx")
  cat("✓ Validation report saved: outputs/Randomization_Validation_Report.xlsx\n\n")
  
  return(validation_results)
}

# ==============================================================================
# 3. Generate Sealed Envelopes
# ==============================================================================

generate_sealed_envelopes <- function(randomization_list, 
                                     site_number = NULL,
                                     study_id = "STUDY-001",
                                     output_dir = "outputs/sealed_envelopes") {
  
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          SEALED ENVELOPE GENERATION                            ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  # Filter by site if specified
  if (!is.null(site_number)) {
    envelope_list <- randomization_list %>%
      filter(grepl(site_number, Randomization_Number) | TRUE)  # Adjust filter as needed
    cat(glue("Generating envelopes for site: {site_number}\n\n"))
  } else {
    envelope_list <- randomization_list
    cat("Generating envelopes for all sites\n\n")
  }
  
  # Create output directory
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Generate individual envelope documents
  for (i in 1:nrow(envelope_list)) {
    
    rand_num <- envelope_list$Randomization_Number[i]
    treatment <- envelope_list$Treatment[i]
    
    # Create envelope document
    doc <- read_docx()
    
    doc <- doc %>%
      body_add_par("", style = "Normal") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par("EMERGENCY UNBLINDING ENVELOPE", style = "heading 1") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par("CONFIDENTIAL - DO NOT OPEN UNLESS AUTHORIZED", style = "heading 2") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par(strrep("═", 60), style = "Normal") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par(glue("Study: {study_id}"), style = "Normal") %>%
      body_add_par(glue("Randomization Number: {rand_num}"), style = "Normal") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par(strrep("═", 60), style = "Normal") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par("TREATMENT ASSIGNMENT:", style = "heading 2") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par(treatment, style = "heading 1") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par(strrep("═", 60), style = "Normal") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par("INSTRUCTIONS:", style = "heading 3") %>%
      body_add_par("1. This envelope should only be opened in case of emergency", style = "Normal") %>%
      body_add_par("2. Contact Medical Monitor before opening", style = "Normal") %>%
      body_add_par("3. Document opening in Emergency Unblinding Form", style = "Normal") %>%
      body_add_par("4. Notify sponsor within 24 hours", style = "Normal") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par(strrep("═", 60), style = "Normal") %>%
      body_add_par("", style = "Normal") %>%
      body_add_par("Opened by: _________________________________", style = "Normal") %>%
      body_add_par("Date/Time: _________________________________", style = "Normal") %>%
      body_add_par("Reason: _________________________________", style = "Normal")
    
    # Save envelope
    envelope_file <- file.path(output_dir, glue("Envelope_{rand_num}.docx"))
    print(doc, target = envelope_file)
    
    if (i %% 10 == 0) {
      cat(glue("  Generated {i}/{nrow(envelope_list)} envelopes...\n"))
    }
  }
  
  cat(glue("\n✓ Generated {nrow(envelope_list)} sealed envelopes\n"))
  cat(glue("  Location: {output_dir}\n\n"))
  
  # Generate envelope tracking log
  envelope_log <- envelope_list %>%
    mutate(
      Envelope_File = glue("Envelope_{Randomization_Number}.docx"),
      Envelope_Status = "Sealed",
      Opened_Date = as.Date(NA),
      Opened_By = NA_character_,
      Reason = NA_character_
    ) %>%
    select(Randomization_Number, Treatment, Envelope_File, Envelope_Status,
           Opened_Date, Opened_By, Reason)
  
  writexl::write_xlsx(envelope_log, file.path(output_dir, "Envelope_Tracking_Log.xlsx"))
  
  cat("✓ Envelope tracking log created\n")
  cat(glue("  File: {file.path(output_dir, 'Envelope_Tracking_Log.xlsx')}\n\n"))
  
  return(envelope_log)
}

# ==============================================================================
# 4. Generate Randomization Certificate
# ==============================================================================

generate_randomization_certificate <- function(randomization_list,
                                              study_id = "STUDY-001",
                                              generated_by = "Independent Statistician",
                                              validated_by = "") {
  
  cat("Generating randomization certificate...\n")
  
  # Extract metadata
  seed <- unique(randomization_list$Random_Seed)[1]
  generated_date <- unique(randomization_list$Generated_Date)[1]
  n_subjects <- nrow(randomization_list)
  
  # Treatment summary
  treatment_summary <- randomization_list %>%
    count(Treatment, name = "N") %>%
    mutate(Percentage = round(N / sum(N) * 100, 1))
  
  # Create certificate
  doc <- read_docx()
  
  doc <- doc %>%
    body_add_par("RANDOMIZATION LIST CERTIFICATE", style = "heading 1") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par(glue("Study: {study_id}"), style = "Normal") %>%
    body_add_par(glue("Date: {Sys.Date()}"), style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("RANDOMIZATION DETAILS", style = "heading 2") %>%
    body_add_par(glue("Total Randomization Numbers: {n_subjects}"), style = "Normal") %>%
    body_add_par(glue("Random Seed: {seed}"), style = "Normal") %>%
    body_add_par(glue("Generation Date: {generated_date}"), style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("TREATMENT ALLOCATION", style = "heading 2")
  
  # Add treatment summary table
  ft <- flextable(treatment_summary) %>%
    theme_booktabs() %>%
    autofit()
  
  doc <- doc %>%
    body_add_flextable(ft) %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("VALIDATION", style = "heading 2") %>%
    body_add_par("☐ Randomization list validated", style = "Normal") %>%
    body_add_par("☐ Sealed envelopes generated", style = "Normal") %>%
    body_add_par("☐ Envelopes distributed to sites", style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par("SIGNATURES", style = "heading 2") %>%
    body_add_par(glue("Generated by: {generated_by}"), style = "Normal") %>%
    body_add_par("Signature: _________________________________", style = "Normal") %>%
    body_add_par(glue("Date: {Sys.Date()}"), style = "Normal") %>%
    body_add_par("", style = "Normal") %>%
    body_add_par(glue("Validated by: {validated_by}"), style = "Normal") %>%
    body_add_par("Signature: _________________________________", style = "Normal") %>%
    body_add_par("Date: _________________________________", style = "Normal")
  
  # Save certificate
  cert_file <- "outputs/Randomization_Certificate.docx"
  print(doc, target = cert_file)
  
  cat(glue("✓ Randomization certificate created: {cert_file}\n\n"))
  
  return(cert_file)
}

# ==============================================================================
# 5. Complete Randomization Workflow
# ==============================================================================

complete_randomization_workflow <- function(
  n_subjects = 100,
  treatments = c("Treatment A", "Placebo"),
  allocation_ratio = c(1, 1),
  randomization_type = "block",
  block_size = 4,
  seed = 12345,
  study_id = "STUDY-001",
  generated_by = "Independent Statistician",
  validated_by = "QC Statistician"
) {
  
  cat("\n")
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          COMPLETE RANDOMIZATION WORKFLOW                       ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  # Step 1: Generate randomization list
  cat("Step 1: Generating master randomization list...\n")
  cat(strrep("-", 60), "\n")
  randomization_list <- generate_master_randomization_list(
    n_subjects = n_subjects,
    treatments = treatments,
    allocation_ratio = allocation_ratio,
    randomization_type = randomization_type,
    block_size = block_size,
    seed = seed,
    study_id = study_id,
    generated_by = generated_by
  )
  
  # Save master list (CONFIDENTIAL)
  writexl::write_xlsx(randomization_list, "outputs/Master_Randomization_List_CONFIDENTIAL.xlsx")
  cat("✓ Master randomization list saved (CONFIDENTIAL)\n\n")
  
  # Step 2: Validate randomization list
  cat("Step 2: Validating randomization list...\n")
  cat(strrep("-", 60), "\n")
  validation_results <- validate_randomization_list(
    randomization_list,
    expected_allocation_ratio = allocation_ratio,
    block_size = block_size
  )
  
  # Step 3: Generate sealed envelopes
  cat("Step 3: Generating sealed envelopes...\n")
  cat(strrep("-", 60), "\n")
  envelope_log <- generate_sealed_envelopes(
    randomization_list,
    study_id = study_id
  )
  
  # Step 4: Generate certificate
  cat("Step 4: Generating randomization certificate...\n")
  cat(strrep("-", 60), "\n")
  certificate_file <- generate_randomization_certificate(
    randomization_list,
    study_id = study_id,
    generated_by = generated_by,
    validated_by = validated_by
  )
  
  cat("╔════════════════════════════════════════════════════════════════╗\n")
  cat("║          RANDOMIZATION WORKFLOW COMPLETE                       ║\n")
  cat("╚════════════════════════════════════════════════════════════════╝\n\n")
  
  cat("Generated Files:\n")
  cat("  1. Master_Randomization_List_CONFIDENTIAL.xlsx\n")
  cat("  2. Randomization_Validation_Report.xlsx\n")
  cat("  3. Sealed envelopes (outputs/sealed_envelopes/)\n")
  cat("  4. Envelope_Tracking_Log.xlsx\n")
  cat("  5. Randomization_Certificate.docx\n\n")
  
  cat("Next Steps:\n")
  cat("  1. ☐ Review and sign randomization certificate\n")
  cat("  2. ☐ Secure master randomization list\n")
  cat("  3. ☐ Print and seal envelopes\n")
  cat("  4. ☐ Distribute envelopes to sites\n")
  cat("  5. ☐ Train site staff on emergency unblinding procedures\n\n")
  
  return(list(
    randomization_list = randomization_list,
    validation_results = validation_results,
    envelope_log = envelope_log,
    certificate_file = certificate_file
  ))
}

# ==============================================================================
# Example Usage
# ==============================================================================

cat("Randomization List Generation Functions Loaded\n\n")

cat("Example usage:\n\n")

cat("# Complete workflow:\n")
cat('complete_randomization_workflow(\n')
cat('  n_subjects = 100,\n')
cat('  treatments = c("Treatment A", "Placebo"),\n')
cat('  allocation_ratio = c(1, 1),\n')
cat('  randomization_type = "block",\n')
cat('  block_size = 4,\n')
cat('  seed = 12345\n')
cat(')\n\n')
