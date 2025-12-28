# ==============================================================================
# Sample Size and Power Calculations
# Script: sample_size_calculations.R
# Purpose: Calculate sample sizes for various study designs
# ==============================================================================

source("R/setup/00_install_packages.R")

# Install additional packages if needed
if (!require("pwr")) install.packages("pwr")
if (!require("powerSurvEpi")) install.packages("powerSurvEpi")
if (!require("gsDesign")) install.packages("gsDesign")

library(pwr)
library(powerSurvEpi)
library(gsDesign)
library(dplyr)
library(ggplot2)

cat("\n========================================\n")
cat("Sample Size & Power Calculations\n")
cat("========================================\n\n")

# ==============================================================================
# 1. Two-Sample T-Test (Continuous Endpoint)
# ==============================================================================

cat("[1] Two-Sample T-Test Sample Size\n")
cat(strrep("-", 80), "\n")

calculate_ttest_sample_size <- function(effect_size, alpha = 0.05, power = 0.80, 
                                       ratio = 1, alternative = "two.sided") {
  
  result <- pwr.t.test(
    d = effect_size,
    sig.level = alpha,
    power = power,
    type = "two.sample",
    alternative = alternative
  )
  
  n_per_group <- ceiling(result$n)
  total_n <- n_per_group * 2
  
  cat(glue("Effect Size (Cohen's d): {effect_size}\n"))
  cat(glue("Alpha: {alpha}\n"))
  cat(glue("Power: {power}\n"))
  cat(glue("Sample Size per Group: {n_per_group}\n"))
  cat(glue("Total Sample Size: {total_n}\n\n"))
  
  return(list(
    n_per_group = n_per_group,
    total_n = total_n,
    power = power,
    effect_size = effect_size,
    result = result
  ))
}

# Example: Detect medium effect size (0.5)
ttest_ss <- calculate_ttest_sample_size(effect_size = 0.5, power = 0.80)

# ==============================================================================
# 2. Proportion Test (Binary Endpoint)
# ==============================================================================

cat("[2] Two-Proportion Test Sample Size\n")
cat(strrep("-", 80), "\n")

calculate_proportion_sample_size <- function(p1, p2, alpha = 0.05, power = 0.80,
                                            alternative = "two.sided") {
  
  result <- pwr.2p.test(
    h = ES.h(p1, p2),
    sig.level = alpha,
    power = power,
    alternative = alternative
  )
  
  n_per_group <- ceiling(result$n)
  total_n <- n_per_group * 2
  
  cat(glue("Proportion in Group 1: {p1}\n"))
  cat(glue("Proportion in Group 2: {p2}\n"))
  cat(glue("Alpha: {alpha}\n"))
  cat(glue("Power: {power}\n"))
  cat(glue("Sample Size per Group: {n_per_group}\n"))
  cat(glue("Total Sample Size: {total_n}\n\n"))
  
  return(list(
    n_per_group = n_per_group,
    total_n = total_n,
    p1 = p1,
    p2 = p2,
    result = result
  ))
}

# Example: Response rate 60% vs 40%
prop_ss <- calculate_proportion_sample_size(p1 = 0.60, p2 = 0.40, power = 0.80)

# ==============================================================================
# 3. Survival Analysis (Time-to-Event)
# ==============================================================================

cat("[3] Survival Analysis Sample Size\n")
cat(strrep("-", 80), "\n")

calculate_survival_sample_size <- function(median_control, median_treatment,
                                          alpha = 0.05, power = 0.80,
                                          accrual_time = 12, followup_time = 12) {
  
  # Calculate hazard ratio
  hr <- log(2) / median_treatment / (log(2) / median_control)
  
  # Calculate required number of events
  z_alpha <- qnorm(1 - alpha/2)
  z_beta <- qnorm(power)
  
  events_required <- ceiling(4 * (z_alpha + z_beta)^2 / (log(hr))^2)
  
  # Estimate total sample size (assuming ~70% event rate)
  event_rate <- 0.70
  total_n <- ceiling(events_required / event_rate)
  
  cat(glue("Median Survival (Control): {median_control} months\n"))
  cat(glue("Median Survival (Treatment): {median_treatment} months\n"))
  cat(glue("Hazard Ratio: {round(hr, 3)}\n"))
  cat(glue("Alpha: {alpha}\n"))
  cat(glue("Power: {power}\n"))
  cat(glue("Required Events: {events_required}\n"))
  cat(glue("Estimated Total Sample Size: {total_n}\n\n"))
  
  return(list(
    events_required = events_required,
    total_n = total_n,
    hazard_ratio = hr,
    median_control = median_control,
    median_treatment = median_treatment
  ))
}

# Example: Median survival 12 months vs 18 months
surv_ss <- calculate_survival_sample_size(
  median_control = 12,
  median_treatment = 18,
  power = 0.80
)

# ==============================================================================
# 4. ANOVA (Multiple Groups)
# ==============================================================================

cat("[4] One-Way ANOVA Sample Size\n")
cat(strrep("-", 80), "\n")

calculate_anova_sample_size <- function(k, effect_size, alpha = 0.05, power = 0.80) {
  
  result <- pwr.anova.test(
    k = k,
    f = effect_size,
    sig.level = alpha,
    power = power
  )
  
  n_per_group <- ceiling(result$n)
  total_n <- n_per_group * k
  
  cat(glue("Number of Groups: {k}\n"))
  cat(glue("Effect Size (f): {effect_size}\n"))
  cat(glue("Alpha: {alpha}\n"))
  cat(glue("Power: {power}\n"))
  cat(glue("Sample Size per Group: {n_per_group}\n"))
  cat(glue("Total Sample Size: {total_n}\n\n"))
  
  return(list(
    n_per_group = n_per_group,
    total_n = total_n,
    k = k,
    result = result
  ))
}

# Example: 3 treatment groups, medium effect
anova_ss <- calculate_anova_sample_size(k = 3, effect_size = 0.25, power = 0.80)

# ==============================================================================
# 5. Power Curve Visualization
# ==============================================================================

cat("[5] Generating Power Curves\n")
cat(strrep("-", 80), "\n")

generate_power_curve <- function(effect_sizes = seq(0.2, 0.8, 0.1),
                                sample_sizes = seq(20, 200, 20),
                                alpha = 0.05) {
  
  power_data <- expand.grid(
    effect_size = effect_sizes,
    n = sample_sizes
  ) %>%
    rowwise() %>%
    mutate(
      power = pwr.t.test(d = effect_size, n = n, sig.level = alpha, 
                        type = "two.sample")$power
    ) %>%
    ungroup()
  
  p <- ggplot(power_data, aes(x = n, y = power, color = factor(effect_size))) +
    geom_line(size = 1) +
    geom_hline(yintercept = 0.80, linetype = "dashed", color = "red") +
    labs(
      title = "Power Curves for Two-Sample T-Test",
      x = "Sample Size per Group",
      y = "Statistical Power",
      color = "Effect Size\n(Cohen's d)",
      caption = glue("Alpha = {alpha}; Red line indicates 80% power")
    ) +
    scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      legend.position = "right"
    )
  
  ggsave("outputs/biostat/Power_Curve.png", p, width = 10, height = 6, dpi = 300)
  cat("✓ Power curve saved: outputs/biostat/Power_Curve.png\n\n")
  
  return(power_data)
}

power_curve_data <- generate_power_curve()

# ==============================================================================
# 6. Group Sequential Design (Interim Analysis)
# ==============================================================================

cat("[6] Group Sequential Design\n")
cat(strrep("-", 80), "\n")

design_group_sequential <- function(k = 3, alpha = 0.025, beta = 0.20,
                                   timing = NULL) {
  
  if (is.null(timing)) {
    timing <- (1:k) / k  # Equal spacing
  }
  
  gs_design <- gsDesign(
    k = k,
    test.type = 1,  # One-sided
    alpha = alpha,
    beta = beta,
    timing = timing,
    sfu = sfLDOF  # Lan-DeMets O'Brien-Fleming
  )
  
  cat(glue("Number of Interim Analyses: {k}\n"))
  cat(glue("Alpha (one-sided): {alpha}\n"))
  cat(glue("Power: {1 - beta}\n"))
  cat(glue("Alpha Spending Function: Lan-DeMets O'Brien-Fleming\n\n"))
  
  cat("Interim Analysis Schedule:\n")
  for (i in 1:k) {
    cat(glue("  Analysis {i}: {round(timing[i] * 100, 1)}% information\n"))
    cat(glue("    Efficacy Boundary (Z): {round(gs_design$upper$bound[i], 3)}\n"))
    cat(glue("    Alpha Spent: {round(gs_design$upper$spend[i], 5)}\n\n"))
  }
  
  return(gs_design)
}

# Example: 3 interim analyses
gs_design <- design_group_sequential(k = 3, alpha = 0.025, beta = 0.20)

# ==============================================================================
# Export Sample Size Summary
# ==============================================================================

cat("[7] Exporting Sample Size Summary\n")
cat(strrep("-", 80), "\n")

sample_size_summary <- tibble(
  Analysis_Type = c("Two-Sample T-Test", "Two-Proportion Test", 
                    "Survival Analysis", "One-Way ANOVA"),
  Sample_Size_Per_Group = c(
    ttest_ss$n_per_group,
    prop_ss$n_per_group,
    NA,
    anova_ss$n_per_group
  ),
  Total_Sample_Size = c(
    ttest_ss$total_n,
    prop_ss$total_n,
    surv_ss$total_n,
    anova_ss$total_n
  ),
  Power = c(0.80, 0.80, 0.80, 0.80),
  Alpha = c(0.05, 0.05, 0.05, 0.05),
  Effect_Parameter = c(
    glue("d = {ttest_ss$effect_size}"),
    glue("p1 = {prop_ss$p1}, p2 = {prop_ss$p2}"),
    glue("HR = {round(surv_ss$hazard_ratio, 3)}"),
    glue("f = 0.25, k = {anova_ss$k}")
  )
)

writexl::write_xlsx(sample_size_summary, "outputs/biostat/Sample_Size_Summary.xlsx")

cat("✓ Sample size summary saved: outputs/biostat/Sample_Size_Summary.xlsx\n\n")

cat("========================================\n")
cat("✓ Sample size calculations complete!\n")
cat("========================================\n\n")
