# ==============================================================================
# Figure 14.6: Waterfall Plot for Best Response
# Script: figure_waterfall_plot.R
# Purpose: Generate waterfall plot showing best tumor response
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

library(ggplot2)

cat("\n========================================\n")
cat("Figure 14.6: Waterfall Plot\n")
cat("========================================\n\n")

# Read ADSL
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(ITTFL == "Y")

# ==============================================================================
# Simulate Tumor Response Data (for demonstration)
# ==============================================================================

cat("Preparing tumor response data...\n")

# In real analysis, this would come from tumor assessment data
# For demonstration, we'll simulate percentage change from baseline
set.seed(123)
waterfall_data <- adsl %>%
  mutate(
    # Simulate best percentage change from baseline in tumor size
    Best_Pct_Change = rnorm(n(), mean = -15, sd = 30),
    Best_Pct_Change = pmin(Best_Pct_Change, 50),  # Cap at +50%
    Best_Pct_Change = pmax(Best_Pct_Change, -100), # Floor at -100%
    
    # Response category
    Response = case_when(
      Best_Pct_Change <= -30 ~ "Partial Response",
      Best_Pct_Change > -30 & Best_Pct_Change < 20 ~ "Stable Disease",
      Best_Pct_Change >= 20 ~ "Progressive Disease",
      TRUE ~ "Not Evaluable"
    ),
    
    # Color by response
    Response_Color = case_when(
      Response == "Partial Response" ~ "#2E7D32",
      Response == "Stable Disease" ~ "#FFA726",
      Response == "Progressive Disease" ~ "#D32F2F",
      TRUE ~ "#757575"
    )
  ) %>%
  arrange(Best_Pct_Change) %>%
  mutate(Subject_Order = row_number())

# ==============================================================================
# Create Waterfall Plot
# ==============================================================================

cat("Creating waterfall plot...\n")

p <- ggplot(waterfall_data, aes(x = Subject_Order, y = Best_Pct_Change, fill = Response)) +
  geom_bar(stat = "identity", width = 1) +
  geom_hline(yintercept = 0, color = "black", size = 0.5) +
  geom_hline(yintercept = -30, linetype = "dashed", color = "darkgreen", size = 0.5) +
  geom_hline(yintercept = 20, linetype = "dashed", color = "darkred", size = 0.5) +
  
  # Annotations
  annotate("text", x = nrow(waterfall_data) * 0.95, y = -32, 
           label = "PR threshold (-30%)", hjust = 1, size = 3, color = "darkgreen") +
  annotate("text", x = nrow(waterfall_data) * 0.95, y = 22, 
           label = "PD threshold (+20%)", hjust = 1, size = 3, color = "darkred") +
  
  labs(
    title = "Waterfall Plot: Best Percentage Change from Baseline in Tumor Size",
    subtitle = "ITT Population",
    x = "Individual Subjects (Ordered by Response)",
    y = "Best % Change from Baseline in Target Lesion Sum",
    fill = "Best Response",
    caption = glue("Generated: {Sys.Date()}\nPR = Partial Response (≤-30%); PD = Progressive Disease (≥+20%)")
  ) +
  scale_fill_manual(values = c(
    "Partial Response" = "#2E7D32",
    "Stable Disease" = "#FFA726",
    "Progressive Disease" = "#D32F2F",
    "Not Evaluable" = "#757575"
  )) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(size = 11),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
    axis.text.y = element_text(size = 10),
    legend.position = "bottom",
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  )

# Save figure
save_figure(p, "Figure_14_6_Waterfall_Plot", width = 12, height = 7)

# ==============================================================================
# Response Summary
# ==============================================================================

cat("\nGenerating response summary...\n")

response_summary <- waterfall_data %>%
  count(TRT01P, Response) %>%
  group_by(TRT01P) %>%
  mutate(
    Total = sum(n),
    Percent = n / Total * 100,
    `n (%)` = sprintf("%d (%.1f%%)", n, Percent)
  ) %>%
  select(Treatment = TRT01P, Response, `n (%)`)

# Save summary
writexl::write_xlsx(response_summary, "outputs/tlf/tables/Table_14_6_Response_Summary.xlsx")

cat("\n========================================\n")
cat("✓ Waterfall plot generation complete!\n")
cat("========================================\n\n")
