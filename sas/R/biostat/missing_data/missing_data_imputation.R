# ==============================================================================
# Missing Data Handling and Imputation
# Script: missing_data_imputation.R
# Purpose: Multiple imputation and sensitivity analyses for missing data
# ==============================================================================

source("R/setup/00_install_packages.R")

# Install additional packages
if (!require("mice")) install.packages("mice")
if (!require("mitools")) install.packages("mitools")
if (!require("VIM")) install.packages("VIM")

library(mice)
library(mitools)
library(VIM)
library(dplyr)
library(ggplot2)

cat("\n========================================\n")
cat("Missing Data Handling & Imputation\n")
cat("========================================\n\n")

# Read ADSL data
adsl <- haven::read_sas(file.path("data/adam", "adsl.sas7bdat")) %>%
  tibble::as_tibble()

cat(glue("Loaded {nrow(adsl)} subjects\n\n"))

# ==============================================================================
# 1. Missing Data Pattern Analysis
# ==============================================================================

cat("[1] Missing Data Pattern Analysis\n")
cat(strrep("-", 80), "\n")

# Select key variables for analysis
analysis_vars <- adsl %>%
  select(AGE, SEX, RACE, TRT01P, TRTDURD, DCSREAS)

# Visualize missing data pattern
png("outputs/biostat/Missing_Data_Pattern.png", width = 10, height = 8, units = "in", res = 300)
md.pattern(analysis_vars, rotate.names = TRUE)
dev.off()

cat("✓ Missing data pattern saved: outputs/biostat/Missing_Data_Pattern.png\n")

# Missing data summary
missing_summary <- analysis_vars %>%
  summarise(across(everything(), ~sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "Variable", values_to = "Missing_Count") %>%
  mutate(
    Total = nrow(analysis_vars),
    Missing_Percent = round(Missing_Count / Total * 100, 2)
  ) %>%
  arrange(desc(Missing_Percent))

cat("\nMissing Data Summary:\n")
print(missing_summary)

writexl::write_xlsx(missing_summary, "outputs/biostat/Missing_Data_Summary.xlsx")
cat("\n✓ Missing data summary saved: outputs/biostat/Missing_Data_Summary.xlsx\n\n")

# ==============================================================================
# 2. Multiple Imputation using MICE
# ==============================================================================

cat("[2] Multiple Imputation (MICE)\n")
cat(strrep("-", 80), "\n")

# Perform multiple imputation
# m = number of imputed datasets
# method = imputation method (pmm = predictive mean matching)
set.seed(123)

imputed_data <- mice(
  analysis_vars,
  m = 5,                    # 5 imputed datasets
  method = "pmm",           # Predictive mean matching
  maxit = 10,               # Maximum iterations
  seed = 123,
  printFlag = FALSE
)

cat("Multiple Imputation Summary:\n")
print(imputed_data)

# Check convergence
png("outputs/biostat/MI_Convergence.png", width = 10, height = 8, units = "in", res = 300)
plot(imputed_data)
dev.off()

cat("\n✓ Convergence plot saved: outputs/biostat/MI_Convergence.png\n")

# Compare imputed vs observed values
png("outputs/biostat/MI_Density_Comparison.png", width = 12, height = 8, units = "in", res = 300)
densityplot(imputed_data)
dev.off()

cat("✓ Density comparison saved: outputs/biostat/MI_Density_Comparison.png\n\n")

# ==============================================================================
# 3. Analyze Imputed Datasets
# ==============================================================================

cat("[3] Analyzing Imputed Datasets\n")
cat(strrep("-", 80), "\n")

# Example: Linear regression on imputed data
# Fit model to each imputed dataset
fit_imputed <- with(imputed_data, 
                    lm(TRTDURD ~ AGE + SEX + TRT01P))

# Pool results using Rubin's rules
pooled_results <- pool(fit_imputed)

cat("Pooled Analysis Results:\n")
print(summary(pooled_results))

# Extract pooled estimates
pooled_estimates <- summary(pooled_results) %>%
  as_tibble() %>%
  mutate(
    `95% CI Lower` = estimate - 1.96 * std.error,
    `95% CI Upper` = estimate + 1.96 * std.error,
    `P-value` = 2 * (1 - pnorm(abs(statistic)))
  )

writexl::write_xlsx(pooled_estimates, "outputs/biostat/MI_Pooled_Results.xlsx")
cat("\n✓ Pooled results saved: outputs/biostat/MI_Pooled_Results.xlsx\n\n")

# ==============================================================================
# 4. Sensitivity Analyses for Missing Data
# ==============================================================================

cat("[4] Sensitivity Analyses\n")
cat(strrep("-", 80), "\n")

# Read ADLB for sensitivity analysis example
adlb <- haven::read_sas(file.path("data/adam", "adlb.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y", PARAMCD == "HGB")

# 4.1 Complete Case Analysis (CCA)
cat("4.1 Complete Case Analysis\n")
cca_data <- adlb %>% filter(!is.na(CHG))
cca_result <- t.test(CHG ~ TRT01P, data = cca_data)
cat(glue("  Mean Difference: {round(diff(cca_result$estimate), 2)}\n"))
cat(glue("  P-value: {format.pval(cca_result$p.value, digits = 3)}\n\n"))

# 4.2 Last Observation Carried Forward (LOCF)
cat("4.2 Last Observation Carried Forward (LOCF)\n")
locf_data <- adlb %>%
  arrange(USUBJID, ADY) %>%
  group_by(USUBJID) %>%
  fill(CHG, .direction = "down") %>%
  slice_tail(n = 1) %>%
  ungroup()

locf_result <- t.test(CHG ~ TRT01P, data = locf_data)
cat(glue("  Mean Difference: {round(diff(locf_result$estimate), 2)}\n"))
cat(glue("  P-value: {format.pval(locf_result$p.value, digits = 3)}\n\n"))

# 4.3 Worst Case Imputation
cat("4.3 Worst Case Imputation\n")
worst_case_data <- adlb %>%
  group_by(USUBJID) %>%
  summarise(
    TRT01P = first(TRT01P),
    CHG = if_else(all(is.na(CHG)), 
                  min(adlb$CHG, na.rm = TRUE),  # Worst case
                  mean(CHG, na.rm = TRUE)),
    .groups = "drop"
  )

worst_case_result <- t.test(CHG ~ TRT01P, data = worst_case_data)
cat(glue("  Mean Difference: {round(diff(worst_case_result$estimate), 2)}\n"))
cat(glue("  P-value: {format.pval(worst_case_result$p.value, digits = 3)}\n\n"))

# 4.4 Best Case Imputation
cat("4.4 Best Case Imputation\n")
best_case_data <- adlb %>%
  group_by(USUBJID) %>%
  summarise(
    TRT01P = first(TRT01P),
    CHG = if_else(all(is.na(CHG)), 
                  max(adlb$CHG, na.rm = TRUE),  # Best case
                  mean(CHG, na.rm = TRUE)),
    .groups = "drop"
  )

best_case_result <- t.test(CHG ~ TRT01P, data = best_case_data)
cat(glue("  Mean Difference: {round(diff(best_case_result$estimate), 2)}\n"))
cat(glue("  P-value: {format.pval(best_case_result$p.value, digits = 3)}\n\n"))

# ==============================================================================
# 5. Sensitivity Analysis Summary
# ==============================================================================

cat("[5] Sensitivity Analysis Summary\n")
cat(strrep("-", 80), "\n")

sensitivity_summary <- tibble(
  Method = c("Complete Case Analysis", "LOCF", "Worst Case", "Best Case", "Multiple Imputation"),
  Mean_Difference = c(
    diff(cca_result$estimate),
    diff(locf_result$estimate),
    diff(worst_case_result$estimate),
    diff(best_case_result$estimate),
    NA  # Would need to calculate from MI results
  ),
  P_Value = c(
    cca_result$p.value,
    locf_result$p.value,
    worst_case_result$p.value,
    best_case_result$p.value,
    NA
  ),
  N_Analyzed = c(
    nrow(cca_data),
    nrow(locf_data),
    nrow(worst_case_data),
    nrow(best_case_data),
    nrow(adsl)
  )
) %>%
  mutate(
    Mean_Difference = round(Mean_Difference, 2),
    P_Value = format.pval(P_Value, digits = 3)
  )

cat("\nSensitivity Analysis Results:\n")
print(sensitivity_summary)

writexl::write_xlsx(sensitivity_summary, "outputs/biostat/Sensitivity_Analysis_Summary.xlsx")
cat("\n✓ Sensitivity analysis summary saved: outputs/biostat/Sensitivity_Analysis_Summary.xlsx\n\n")

# ==============================================================================
# 6. Tipping Point Analysis
# ==============================================================================

cat("[6] Tipping Point Analysis\n")
cat(strrep("-", 80), "\n")

# Vary the imputed value for missing data to find tipping point
imputation_values <- seq(-10, 10, by = 1)
tipping_results <- tibble()

for (imp_val in imputation_values) {
  tipped_data <- adlb %>%
    group_by(USUBJID) %>%
    summarise(
      TRT01P = first(TRT01P),
      CHG = if_else(all(is.na(CHG)), imp_val, mean(CHG, na.rm = TRUE)),
      .groups = "drop"
    )
  
  tipped_result <- t.test(CHG ~ TRT01P, data = tipped_data)
  
  tipping_results <- bind_rows(tipping_results, tibble(
    Imputation_Value = imp_val,
    Mean_Difference = diff(tipped_result$estimate),
    P_Value = tipped_result$p.value,
    Significant = tipped_result$p.value < 0.05
  ))
}

# Plot tipping point
p_tipping <- ggplot(tipping_results, aes(x = Imputation_Value, y = P_Value)) +
  geom_line(size = 1) +
  geom_point(aes(color = Significant), size = 3) +
  geom_hline(yintercept = 0.05, linetype = "dashed", color = "red") +
  labs(
    title = "Tipping Point Analysis",
    subtitle = "P-value vs. Imputed Value for Missing Data",
    x = "Imputed Value for Missing Data",
    y = "P-value",
    color = "Significant\n(p < 0.05)"
  ) +
  scale_color_manual(values = c("TRUE" = "darkgreen", "FALSE" = "darkred")) +
  theme_minimal()

ggsave("outputs/biostat/Tipping_Point_Analysis.png", p_tipping, width = 10, height = 6, dpi = 300)
cat("✓ Tipping point plot saved: outputs/biostat/Tipping_Point_Analysis.png\n\n")

cat("========================================\n")
cat("✓ Missing data analysis complete!\n")
cat("========================================\n\n")
