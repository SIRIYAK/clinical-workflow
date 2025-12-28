# ==============================================================================
# Figure 14.5: Forest Plot for Treatment Effect
# Script: figure_forest_plot.R
# Purpose: Generate forest plot showing treatment effects across subgroups
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

library(ggplot2)
library(forestplot)

cat("\n========================================\n")
cat("Figure 14.5: Forest Plot\n")
cat("========================================\n\n")

# Read ADSL
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(ITTFL == "Y")

# ==============================================================================
# Calculate Treatment Effects by Subgroup
# ==============================================================================

cat("Calculating treatment effects by subgroup...\n")

# Define subgroups
subgroups <- list(
  list(name = "Overall", var = NULL, levels = NULL),
  list(name = "Age", var = "AGEGR1", levels = c("<18", "18-64", "65-74", ">=75")),
  list(name = "Sex", var = "SEX", levels = c("M", "F")),
  list(name = "Race", var = "RACE", levels = c("WHITE", "BLACK OR AFRICAN AMERICAN", "ASIAN", "OTHER"))
)

forest_data <- tibble()

for (subgroup in subgroups) {
  
  if (is.null(subgroup$var)) {
    # Overall analysis
    subgroup_data <- adsl
    
    # Calculate hazard ratio (simplified - using death as outcome)
    trt_groups <- unique(subgroup_data$TRT01P)
    if (length(trt_groups) == 2) {
      # Binary outcome: death
      deaths_trt1 <- sum(subgroup_data$DTHFL[subgroup_data$TRT01P == trt_groups[1]] == "Y", na.rm = TRUE)
      n_trt1 <- sum(subgroup_data$TRT01P == trt_groups[1])
      deaths_trt2 <- sum(subgroup_data$DTHFL[subgroup_data$TRT01P == trt_groups[2]] == "Y", na.rm = TRUE)
      n_trt2 <- sum(subgroup_data$TRT01P == trt_groups[2])
      
      # Calculate odds ratio
      or <- (deaths_trt1 / (n_trt1 - deaths_trt1)) / (deaths_trt2 / (n_trt2 - deaths_trt2))
      
      # Approximate 95% CI (simplified)
      log_or <- log(or)
      se_log_or <- sqrt(1/deaths_trt1 + 1/(n_trt1-deaths_trt1) + 1/deaths_trt2 + 1/(n_trt2-deaths_trt2))
      ci_lower <- exp(log_or - 1.96 * se_log_or)
      ci_upper <- exp(log_or + 1.96 * se_log_or)
      
      forest_data <- bind_rows(forest_data, tibble(
        Subgroup = "Overall",
        Level = "",
        N = nrow(subgroup_data),
        OR = or,
        CI_Lower = ci_lower,
        CI_Upper = ci_upper
      ))
    }
    
  } else {
    # Subgroup analysis
    for (level in subgroup$levels) {
      subgroup_data <- adsl %>% filter(!!sym(subgroup$var) == level)
      
      if (nrow(subgroup_data) < 10) next  # Skip if too few subjects
      
      trt_groups <- unique(subgroup_data$TRT01P)
      if (length(trt_groups) == 2) {
        deaths_trt1 <- sum(subgroup_data$DTHFL[subgroup_data$TRT01P == trt_groups[1]] == "Y", na.rm = TRUE)
        n_trt1 <- sum(subgroup_data$TRT01P == trt_groups[1])
        deaths_trt2 <- sum(subgroup_data$DTHFL[subgroup_data$TRT01P == trt_groups[2]] == "Y", na.rm = TRUE)
        n_trt2 <- sum(subgroup_data$TRT01P == trt_groups[2])
        
        if (deaths_trt1 > 0 && deaths_trt2 > 0) {
          or <- (deaths_trt1 / (n_trt1 - deaths_trt1)) / (deaths_trt2 / (n_trt2 - deaths_trt2))
          log_or <- log(or)
          se_log_or <- sqrt(1/deaths_trt1 + 1/(n_trt1-deaths_trt1) + 1/deaths_trt2 + 1/(n_trt2-deaths_trt2))
          ci_lower <- exp(log_or - 1.96 * se_log_or)
          ci_upper <- exp(log_or + 1.96 * se_log_or)
          
          forest_data <- bind_rows(forest_data, tibble(
            Subgroup = subgroup$name,
            Level = level,
            N = nrow(subgroup_data),
            OR = or,
            CI_Lower = ci_lower,
            CI_Upper = ci_upper
          ))
        }
      }
    }
  }
}

# ==============================================================================
# Create Forest Plot
# ==============================================================================

cat("Creating forest plot...\n")

# Prepare data for forest plot
forest_data <- forest_data %>%
  mutate(
    Label = if_else(Level == "", Subgroup, paste0("  ", Level)),
    OR_text = sprintf("%.2f (%.2f-%.2f)", OR, CI_Lower, CI_Upper),
    N_text = as.character(N)
  ) %>%
  arrange(Subgroup, Level)

# Create forest plot using ggplot2
p <- ggplot(forest_data, aes(y = reorder(Label, row_number()), x = OR)) +
  geom_vline(xintercept = 1, linetype = "dashed", color = "gray50") +
  geom_errorbarh(aes(xmin = CI_Lower, xmax = CI_Upper), height = 0.2) +
  geom_point(size = 3, shape = 18) +
  scale_x_log10(breaks = c(0.25, 0.5, 1, 2, 4)) +
  labs(
    title = "Forest Plot: Treatment Effect Across Subgroups",
    subtitle = "Odds Ratio for Mortality (Treatment vs. Control)",
    x = "Odds Ratio (95% CI)\n← Favors Treatment    Favors Control →",
    y = "",
    caption = glue("Generated: {Sys.Date()}\nDashed line indicates OR = 1 (no effect)")
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11),
    axis.title.x = element_text(size = 11),
    axis.text = element_text(size = 10),
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  )

# Save figure
save_figure(p, "Figure_14_5_Forest_Plot", width = 10, height = 8)

# Save forest data as table
writexl::write_xlsx(forest_data, "outputs/tlf/tables/Table_14_5_Forest_Plot_Data.xlsx")

cat("\n========================================\n")
cat("✓ Forest plot generation complete!\n")
cat("========================================\n\n")
