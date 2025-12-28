# ==============================================================================
# Figure 14.7: Swimmer Plot for Treatment Duration and Response
# Script: figure_swimmer_plot.R
# Purpose: Generate swimmer plot showing treatment duration and key events
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

library(ggplot2)

cat("\n========================================\n")
cat("Figure 14.7: Swimmer Plot\n")
cat("========================================\n\n")

# Read ADSL
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(ITTFL == "Y") %>%
  arrange(TRT01P, desc(TRTDURD))

# ==============================================================================
# Prepare Swimmer Plot Data
# ==============================================================================

cat("Preparing swimmer plot data...\n")

# Create subject order
swimmer_data <- adsl %>%
  mutate(
    Subject_Order = row_number(),
    # Treatment duration in months
    Duration_Months = TRTDURD / 30.44,
    # Event indicators (simulated for demonstration)
    Has_Response = sample(c(TRUE, FALSE), n(), replace = TRUE, prob = c(0.3, 0.7)),
    Response_Time = if_else(Has_Response, runif(n(), 1, Duration_Months * 0.8), NA_real_),
    Has_Progression = sample(c(TRUE, FALSE), n(), replace = TRUE, prob = c(0.4, 0.6)),
    Progression_Time = if_else(Has_Progression, runif(n(), 2, Duration_Months), NA_real_),
    Ongoing = DCSREAS == "COMPLETED"
  )

# ==============================================================================
# Create Swimmer Plot
# ==============================================================================

cat("Creating swimmer plot...\n")

p <- ggplot(swimmer_data, aes(y = Subject_Order)) +
  # Treatment duration bars
  geom_segment(aes(x = 0, xend = Duration_Months, yend = Subject_Order, color = TRT01P),
               size = 2, alpha = 0.7) +
  
  # Response markers
  geom_point(data = swimmer_data %>% filter(!is.na(Response_Time)),
             aes(x = Response_Time), 
             shape = 17, size = 3, color = "darkgreen") +
  
  # Progression markers
  geom_point(data = swimmer_data %>% filter(!is.na(Progression_Time)),
             aes(x = Progression_Time), 
             shape = 4, size = 3, color = "darkred", stroke = 2) +
  
  # Ongoing treatment markers
  geom_point(data = swimmer_data %>% filter(Ongoing),
             aes(x = Duration_Months), 
             shape = 16, size = 2, color = "black") +
  
  labs(
    title = "Swimmer Plot: Treatment Duration and Key Events",
    subtitle = "ITT Population (Ordered by Treatment Duration)",
    x = "Time from Treatment Start (Months)",
    y = "Individual Subjects",
    color = "Treatment",
    caption = glue("Generated: {Sys.Date()}\n▼ = Response; X = Progression; ● = Ongoing treatment")
  ) +
  scale_color_brewer(palette = "Set1") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(size = 11),
    axis.text.x = element_text(size = 10),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    legend.position = "bottom",
    panel.grid.major.y = element_blank(),
    panel.grid.minor = element_blank()
  )

# Save figure
save_figure(p, "Figure_14_7_Swimmer_Plot", width = 12, height = 10)

# ==============================================================================
# Treatment Duration Summary
# ==============================================================================

cat("\nGenerating treatment duration summary...\n")

duration_summary <- swimmer_data %>%
  group_by(TRT01P) %>%
  summarise(
    N = n(),
    `Median Duration (months)` = median(Duration_Months, na.rm = TRUE),
    `Min Duration (months)` = min(Duration_Months, na.rm = TRUE),
    `Max Duration (months)` = max(Duration_Months, na.rm = TRUE),
    `Subjects with Response` = sum(Has_Response, na.rm = TRUE),
    `Subjects with Progression` = sum(Has_Progression, na.rm = TRUE),
    `Ongoing Treatment` = sum(Ongoing, na.rm = TRUE),
    .groups = "drop"
  )

# Save summary
writexl::write_xlsx(duration_summary, "outputs/tlf/tables/Table_14_7_Treatment_Duration_Summary.xlsx")

cat("\n========================================\n")
cat("✓ Swimmer plot generation complete!\n")
cat("========================================\n\n")
