# ==============================================================================
# Figure 14.4: Kaplan-Meier Survival Curve
# Script: figure_km_survival.R
# Purpose: Generate Kaplan-Meier survival curves by treatment
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

library(ggplot2)
library(survival)
library(survminer)

cat("\n========================================\n")
cat("Figure 14.4: Kaplan-Meier Survival\n")
cat("========================================\n\n")

# Read ADSL
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(ITTFL == "Y")

cat(glue("ITT Population: {nrow(adsl)} subjects\n\n"))

# ==============================================================================
# Prepare Survival Data
# ==============================================================================

cat("Preparing survival data...\n")

# Create survival time and event indicator
surv_data <- adsl %>%
  mutate(
    # Time to event (in days from randomization)
    AVAL = if_else(!is.na(DTHDT), 
                   as.numeric(difftime(DTHDT, RANDDT, units = "days")),
                   as.numeric(difftime(EOSDT, RANDDT, units = "days"))),
    # Event indicator (1 = death, 0 = censored)
    CNSR = if_else(DTHFL == "Y", 1, 0)
  ) %>%
  filter(!is.na(AVAL), AVAL >= 0)

# ==============================================================================
# Fit Kaplan-Meier Model
# ==============================================================================

cat("Fitting Kaplan-Meier model...\n")

# Create survival object
surv_obj <- Surv(time = surv_data$AVAL, event = surv_data$CNSR)

# Fit KM model by treatment
km_fit <- survfit(surv_obj ~ TRT01P, data = surv_data)

# ==============================================================================
# Create Kaplan-Meier Plot
# ==============================================================================

cat("Creating Kaplan-Meier plot...\n")

km_plot <- ggsurvplot(
  km_fit,
  data = surv_data,
  pval = TRUE,                    # Add p-value from log-rank test
  conf.int = TRUE,                # Add confidence intervals
  risk.table = TRUE,              # Add risk table
  risk.table.height = 0.25,
  ncensor.plot = FALSE,
  
  # Customize plot
  title = "Kaplan-Meier Survival Curve",
  subtitle = "Overall Survival by Treatment Group (ITT Population)",
  xlab = "Time from Randomization (Days)",
  ylab = "Survival Probability",
  
  # Legend
  legend = "bottom",
  legend.title = "Treatment",
  legend.labs = levels(factor(surv_data$TRT01P)),
  
  # Colors
  palette = "jco",
  
  # Risk table
  risk.table.title = "Number at Risk",
  risk.table.y.text = FALSE,
  
  # Confidence interval
  conf.int.alpha = 0.2,
  
  # Censoring
  censor.shape = "+",
  censor.size = 4,
  
  # Additional elements
  ggtheme = theme_minimal(),
  font.main = c(14, "bold"),
  font.x = c(12, "plain"),
  font.y = c(12, "plain"),
  font.tickslab = c(10, "plain")
)

# Add caption
km_plot$plot <- km_plot$plot +
  labs(caption = glue("Generated: {Sys.Date()}\nLog-rank test p-value shown"))

# ==============================================================================
# Save Figure
# ==============================================================================

cat("Saving Kaplan-Meier plot...\n")

# Save as PNG
ggsave("outputs/tlf/figures/Figure_14_4_KM_Survival.png", 
       plot = km_plot$plot, 
       width = 10, height = 8, dpi = 300)

# Save as PDF
ggsave("outputs/tlf/figures/Figure_14_4_KM_Survival.pdf", 
       plot = km_plot$plot, 
       width = 10, height = 8)

# Save as TIFF
ggsave("outputs/tlf/figures/Figure_14_4_KM_Survival.tiff", 
       plot = km_plot$plot, 
       width = 10, height = 8, dpi = 300, compression = "lzw")

# Save combined plot with risk table
png("outputs/tlf/figures/Figure_14_4_KM_Survival_with_Risk_Table.png", 
    width = 10, height = 10, units = "in", res = 300)
print(km_plot)
dev.off()

cat("✓ Kaplan-Meier plots saved\n")

# ==============================================================================
# Generate Survival Summary Statistics
# ==============================================================================

cat("\nGenerating survival summary statistics...\n")

# Median survival time by treatment
surv_summary <- summary(km_fit)$table %>%
  as.data.frame() %>%
  tibble::rownames_to_column("Treatment") %>%
  mutate(Treatment = gsub("TRT01P=", "", Treatment)) %>%
  select(
    Treatment,
    `N` = records,
    `Events` = events,
    `Median Survival (days)` = median,
    `95% CI Lower` = `0.95LCL`,
    `95% CI Upper` = `0.95UCL`
  )

# Save summary table
writexl::write_xlsx(surv_summary, "outputs/tlf/tables/Table_14_4_KM_Summary_Statistics.xlsx")

cat("✓ Survival summary statistics saved\n")

cat("\n========================================\n")
cat("✓ Kaplan-Meier analysis complete!\n")
cat("========================================\n\n")
