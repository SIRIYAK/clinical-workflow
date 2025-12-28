# ==============================================================================
# Table 14.5: ANOVA for Change from Baseline in Laboratory Parameters
# Script: table_anova_lab.R
# Purpose: Generate ANOVA tables for laboratory change from baseline
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

cat("\n========================================\n")
cat("Table 14.5: ANOVA for Lab Parameters\n")
cat("========================================\n\n")

# Read ADLB
adlb <- haven::read_sas(file.path(PATHS$adam, "adlb.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y", ANL01FL == "Y", !is.na(CHG))

# ==============================================================================
# Perform ANOVA for Each Parameter
# ==============================================================================

cat("Performing ANOVA analyses...\n")

# Select key parameters
key_params <- c("ALT", "AST", "BILI", "CREAT", "HGB", "WBC", "PLAT")

anova_results <- tibble()

for (param in key_params) {
  
  cat(glue("  Analyzing {param}...\n"))
  
  param_data <- adlb %>%
    filter(PARAMCD == param)
  
  if (nrow(param_data) == 0) next
  
  param_name <- unique(param_data$PARAM)[1]
  
  # Perform ANOVA
  anova_model <- aov(CHG ~ TRT01P, data = param_data)
  anova_summary <- summary(anova_model)
  
  # Extract F-statistic and p-value
  f_stat <- anova_summary[[1]]$`F value`[1]
  p_value <- anova_summary[[1]]$`Pr(>F)`[1]
  
  # Calculate LS means by treatment
  ls_means <- param_data %>%
    group_by(TRT01P) %>%
    summarise(
      N = n(),
      LS_Mean = mean(CHG, na.rm = TRUE),
      SE = sd(CHG, na.rm = TRUE) / sqrt(N),
      .groups = "drop"
    )
  
  # Pairwise comparisons (if more than 2 treatments)
  if (length(unique(param_data$TRT01P)) > 1) {
    pairwise_test <- pairwise.t.test(param_data$CHG, param_data$TRT01P, 
                                     p.adjust.method = "bonferroni")
    
    # Extract pairwise p-values
    pw_pvalues <- pairwise_test$p.value
  }
  
  # Compile results
  param_result <- tibble(
    Parameter = param_name,
    `Parameter Code` = param,
    `F-Statistic` = sprintf("%.3f", f_stat),
    `P-value` = format_pvalue(p_value),
    `Significant` = if_else(p_value < 0.05, "Yes", "No")
  )
  
  # Add LS means for each treatment
  for (i in 1:nrow(ls_means)) {
    trt <- ls_means$TRT01P[i]
    param_result[[glue("{trt} LS Mean (SE)")]] <- 
      sprintf("%.2f (%.3f)", ls_means$LS_Mean[i], ls_means$SE[i])
  }
  
  anova_results <- bind_rows(anova_results, param_result)
}

# ==============================================================================
# Create ANOVA Summary Table
# ==============================================================================

cat("\nCreating ANOVA summary table...\n")

title <- "Table 14.5\nANOVA for Change from Baseline in Laboratory Parameters\nSafety Population"

footnotes <- c(
  "ANOVA = Analysis of Variance; LS Mean = Least Squares Mean; SE = Standard Error",
  "Change from baseline = Post-baseline value - Baseline value",
  "P-values from one-way ANOVA",
  "Significant if p < 0.05",
  glue("Generated: {Sys.Date()}")
)

anova_table_ft <- create_regulatory_table(anova_results, title, footnotes)

# ==============================================================================
# Export
# ==============================================================================

cat("Exporting ANOVA table...\n")

export_table_rtf(anova_table_ft, "Table_14_5_ANOVA_Lab_Parameters")
export_table_docx(anova_table_ft, "Table_14_5_ANOVA_Lab_Parameters")

# Also export as Excel for detailed review
writexl::write_xlsx(anova_results, "outputs/tlf/tables/Table_14_5_ANOVA_Lab_Parameters.xlsx")

cat("\n========================================\n")
cat("✓ ANOVA table generation complete!\n")
cat("========================================\n\n")
