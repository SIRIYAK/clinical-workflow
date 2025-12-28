# ==============================================================================
# Figure 14.1: Box Plot of Change from Baseline in Laboratory Values
# Script: figure_lab_boxplot.R
# Purpose: Generate box plots for laboratory change from baseline
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

library(ggplot2)

cat("\n========================================\n")
cat("Figure 14.1: Lab Box Plots\n")
cat("========================================\n\n")

# Read ADLB
adlb <- haven::read_sas(file.path(PATHS$adam, "adlb.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y", ANL01FL == "Y", !is.na(CHG))

# Select key parameters
key_params <- c("ALT", "AST", "BILI", "CREAT", "HGB", "WBC")

for (param in key_params) {
  
  cat(glue("Creating box plot for {param}...\n"))
  
  param_data <- adlb %>%
    filter(PARAMCD == param)
  
  if (nrow(param_data) == 0) next
  
  param_name <- unique(param_data$PARAM)[1]
  
  # Create box plot
  p <- ggplot(param_data, aes(x = TRT01P, y = CHG, fill = TRT01P)) +
    geom_boxplot(outlier.shape = 1, outlier.size = 2) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    labs(
      title = glue("Change from Baseline in {param_name}"),
      subtitle = "Safety Population",
      x = "Treatment Group",
      y = glue("Change from Baseline ({unique(param_data$AVALC)[1]})"),
      caption = glue("Generated: {Sys.Date()}")
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11),
      axis.title = element_text(size = 11),
      axis.text = element_text(size = 10),
      legend.position = "none",
      panel.grid.major.x = element_blank()
    ) +
    scale_fill_brewer(palette = "Set2")
  
  # Save figure
  save_figure(p, glue("Figure_14_1_{param}_Boxplot"), width = 8, height = 6)
}

cat("\n✓ Lab box plots generation complete!\n\n")
