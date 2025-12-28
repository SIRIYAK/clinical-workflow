# ==============================================================================
# Randomization and Treatment Assignment
# Script: randomization_utilities.R
# Purpose: Generate randomization schemes for clinical trials
# ==============================================================================

source("R/setup/00_install_packages.R")

# Install additional packages
if (!require("blockrand")) install.packages("blockrand")
if (!require("randomizeR")) install.packages("randomizeR")

library(blockrand)
library(dplyr)

cat("\n========================================\n")
cat("Randomization Utilities\n")
cat("========================================\n\n")

# ==============================================================================
# 1. Simple Randomization
# ==============================================================================

cat("[1] Simple Randomization\n")
cat(strrep("-", 80), "\n")

simple_randomization <- function(n, treatments, seed = 123) {
  set.seed(seed)
  
  rand_list <- tibble(
    Subject_ID = sprintf("SUBJ-%04d", 1:n),
    Treatment = sample(treatments, n, replace = TRUE),
    Randomization_Date = Sys.Date(),
    Randomization_Number = 1:n
  )
  
  # Summary
  summary_table <- rand_list %>%
    count(Treatment) %>%
    mutate(Percent = round(n / sum(n) * 100, 1))
  
  cat("Simple Randomization Summary:\n")
  print(summary_table)
  cat("\n")
  
  return(rand_list)
}

# Example: 100 subjects, 2 treatments
simple_rand <- simple_randomization(n = 100, treatments = c("Treatment A", "Placebo"))

# ==============================================================================
# 2. Block Randomization
# ==============================================================================

cat("[2] Block Randomization\n")
cat(strrep("-", 80), "\n")

block_randomization <- function(n, treatments, block_size = 4, seed = 123) {
  set.seed(seed)
  
  # Generate block randomization
  rand_blocks <- blockrand(
    n = n,
    num.levels = length(treatments),
    levels = treatments,
    block.sizes = rep(block_size, ceiling(n / block_size)),
    id.prefix = "SUBJ",
    stratum = "All"
  )
  
  rand_list <- rand_blocks %>%
    as_tibble() %>%
    select(
      Subject_ID = id,
      Treatment = treatment,
      Block_ID = block.id,
      Block_Size = block.size
    ) %>%
    mutate(
      Randomization_Date = Sys.Date(),
      Randomization_Number = row_number()
    )
  
  # Summary
  summary_table <- rand_list %>%
    count(Treatment) %>%
    mutate(Percent = round(n / sum(n) * 100, 1))
  
  cat(glue("Block Randomization (Block Size = {block_size}):\n"))
  print(summary_table)
  cat("\n")
  
  return(rand_list)
}

# Example: 100 subjects, 2 treatments, block size 4
block_rand <- block_randomization(n = 100, treatments = c("Treatment A", "Placebo"), block_size = 4)

# ==============================================================================
# 3. Stratified Randomization
# ==============================================================================

cat("[3] Stratified Randomization\n")
cat(strrep("-", 80), "\n")

stratified_randomization <- function(strata_data, treatments, block_size = 4, seed = 123) {
  set.seed(seed)
  
  rand_list <- tibble()
  
  for (stratum in unique(strata_data$Stratum)) {
    stratum_subjects <- strata_data %>% filter(Stratum == stratum)
    n_stratum <- nrow(stratum_subjects)
    
    # Block randomization within stratum
    stratum_rand <- blockrand(
      n = n_stratum,
      num.levels = length(treatments),
      levels = treatments,
      block.sizes = rep(block_size, ceiling(n_stratum / block_size)),
      id.prefix = paste0(stratum, "-SUBJ"),
      stratum = stratum
    )
    
    stratum_rand_clean <- stratum_rand %>%
      as_tibble() %>%
      select(
        Subject_ID = id,
        Treatment = treatment,
        Stratum = stratum,
        Block_ID = block.id
      ) %>%
      mutate(Randomization_Date = Sys.Date())
    
    rand_list <- bind_rows(rand_list, stratum_rand_clean)
  }
  
  # Summary by stratum
  summary_table <- rand_list %>%
    count(Stratum, Treatment) %>%
    group_by(Stratum) %>%
    mutate(Percent = round(n / sum(n) * 100, 1)) %>%
    ungroup()
  
  cat("Stratified Randomization Summary:\n")
  print(summary_table)
  cat("\n")
  
  return(rand_list)
}

# Example: Stratified by age group
strata_example <- tibble(
  Subject_ID = sprintf("SUBJ-%04d", 1:100),
  Stratum = sample(c("Age<65", "Age>=65"), 100, replace = TRUE)
)

stratified_rand <- stratified_randomization(
  strata_data = strata_example,
  treatments = c("Treatment A", "Placebo"),
  block_size = 4
)

# ==============================================================================
# 4. Adaptive Randomization (Minimization)
# ==============================================================================

cat("[4] Adaptive Randomization (Minimization)\n")
cat(strrep("-", 80), "\n")

adaptive_randomization <- function(subject_factors, treatments, existing_assignments = NULL, 
                                  probability = 0.8, seed = 123) {
  set.seed(seed)
  
  if (is.null(existing_assignments)) {
    existing_assignments <- tibble(
      Treatment = character(),
      Factor1 = character(),
      Factor2 = character()
    )
  }
  
  # Calculate imbalance for each treatment
  imbalances <- tibble(Treatment = treatments)
  
  for (trt in treatments) {
    imbalance <- 0
    
    # Factor 1 imbalance
    factor1_count <- existing_assignments %>%
      filter(Treatment == trt, Factor1 == subject_factors$Factor1) %>%
      nrow()
    imbalance <- imbalance + factor1_count
    
    # Factor 2 imbalance
    factor2_count <- existing_assignments %>%
      filter(Treatment == trt, Factor2 == subject_factors$Factor2) %>%
      nrow()
    imbalance <- imbalance + factor2_count
    
    imbalances$Imbalance[imbalances$Treatment == trt] <- imbalance
  }
  
  # Assign to treatment with lowest imbalance (with probability)
  min_imbalance_trt <- imbalances %>%
    filter(Imbalance == min(Imbalance)) %>%
    pull(Treatment)
  
  if (runif(1) < probability) {
    assigned_treatment <- sample(min_imbalance_trt, 1)
  } else {
    assigned_treatment <- sample(treatments, 1)
  }
  
  cat(glue("Subject assigned to: {assigned_treatment}\n"))
  cat("Imbalance scores:\n")
  print(imbalances)
  cat("\n")
  
  return(assigned_treatment)
}

# Example: Minimize on age and sex
subject_new <- list(Factor1 = "Age<65", Factor2 = "Male")
adaptive_assignment <- adaptive_randomization(
  subject_factors = subject_new,
  treatments = c("Treatment A", "Placebo"),
  probability = 0.8
)

# ==============================================================================
# 5. Export Randomization Lists
# ==============================================================================

cat("[5] Exporting Randomization Lists\n")
cat(strrep("-", 80), "\n")

# Export all randomization schemes
rand_exports <- list(
  Simple_Randomization = simple_rand,
  Block_Randomization = block_rand,
  Stratified_Randomization = stratified_rand
)

writexl::write_xlsx(rand_exports, "outputs/biostat/Randomization_Schemes.xlsx")
cat("✓ Randomization schemes saved: outputs/biostat/Randomization_Schemes.xlsx\n\n")

# ==============================================================================
# 6. Randomization Verification
# ==============================================================================

cat("[6] Randomization Verification\n")
cat(strrep("-", 80), "\n")

verify_randomization <- function(rand_list, expected_ratio = c(1, 1)) {
  
  # Check balance
  balance_check <- rand_list %>%
    count(Treatment) %>%
    mutate(
      Expected_n = sum(n) * expected_ratio / sum(expected_ratio),
      Difference = n - Expected_n,
      Percent_Diff = round(Difference / Expected_n * 100, 1)
    )
  
  cat("Randomization Balance Check:\n")
  print(balance_check)
  
  # Chi-square test for balance
  chi_test <- chisq.test(table(rand_list$Treatment))
  cat(glue("\nChi-square test p-value: {format.pval(chi_test$p.value, digits = 3)}\n"))
  
  if (chi_test$p.value > 0.05) {
    cat("✓ Randomization is balanced (p > 0.05)\n")
  } else {
    cat("⚠ Randomization may be imbalanced (p < 0.05)\n")
  }
  
  cat("\n")
  
  return(balance_check)
}

# Verify block randomization
block_verification <- verify_randomization(block_rand, expected_ratio = c(1, 1))

cat("========================================\n")
cat("✓ Randomization utilities complete!\n")
cat("========================================\n\n")
