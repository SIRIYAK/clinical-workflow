# ==============================================================================
# Figure 14.3: Mean Change from Baseline Over Time
# Script: figure_mean_change_time.R
# Purpose: Generate line plots of mean change from baseline over time
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

library(ggplot2)

cat("\n========================================\n")
cat("Figure 14.3: Mean Change Over Time\n")
cat("========================================\n\n")

# Read ADLB
adlb <- haven::read_sas(file.path(PATHS$adam, "adlb.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y", !is.na(CHG))

# Select key parameters
key_params <- c("HGB", "WBC", "PLAT")

for (param in key_params) {
  
  cat(glue("Creating mean change plot for {param}...\n"))
  
  param_data <- adlb %>%
    filter(PARAMCD == param)
  
  if (nrow(param_data) == 0) next
  
  param_name <- unique(param_data$PARAM)[1]
  
  # Calculate mean change by visit
  mean_chg <- param_data %>%
    group_by(TRT01P, ADY) %>%
    summarise(
      Mean_CHG = mean(CHG, na.rm = TRUE),
      SE = sd(CHG, na.rm = TRUE) / sqrt(n()),
      .groups = "drop"
    )
  
  # Create line plot
  p <- ggplot(mean_chg, aes(x = ADY, y = Mean_CHG, color = TRT01P, group = TRT01P)) +
    geom_line(size = 1) +
    geom_point(size = 2) +
    geom_errorbar(aes(ymin = Mean_CHG - SE, ymax = Mean_CHG + SE), width = 5) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
    labs(
      title = glue("Mean Change from Baseline in {param_name} Over Time"),
      subtitle = "Safety Population (Mean ± SE)",
      x = "Study Day",
      y = glue("Mean Change from Baseline ({unique(param_data$AVALC)[1]})"),
      color = "Treatment",
      caption = glue("Generated: {Sys.Date()}")
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11),
      axis.title = element_text(size = 11),
      axis.text = element_text(size = 10),
      legend.position = "bottom"
    ) +
    scale_color_brewer(palette = "Set1")
  
  # Save figure
  save_figure(p, glue("Figure_14_3_{param}_Mean_Change_Time"), width = 10, height = 7)
}

cat("\n✓ Mean change over time plots generation complete!\n\n")
