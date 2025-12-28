# ==============================================================================
# Figure 14.2: AE Incidence Bar Chart
# Script: figure_ae_barchart.R
# Purpose: Generate bar chart of AE incidence by treatment
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")
source("R/tlf/tlf_utilities.R")

library(ggplot2)

cat("\n========================================\n")
cat("Figure 14.2: AE Incidence Bar Chart\n")
cat("========================================\n\n")

# Read data
adsl <- haven::read_sas(file.path(PATHS$adam, "adsl.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y")

adae <- haven::read_sas(file.path(PATHS$adam, "adae.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y", TRTEMFL == "Y")

# Calculate AE incidence
n_per_trt <- adsl %>% count(TRT01P, name = "N")

ae_incidence <- tibble(
  Category = c("Any AE", "Serious AE", "Severe AE", "Related AE", "Leading to Disc.", "Fatal"),
  TRT01P = list(unique(adsl$TRT01P))
) %>%
  unnest(TRT01P)

# Calculate for each category
for (i in 1:nrow(ae_incidence)) {
  cat <- ae_incidence$Category[i]
  trt <- ae_incidence$TRT01P[i]
  
  n_subj <- if (cat == "Any AE") {
    adae %>% filter(TRT01P == trt) %>% distinct(USUBJID) %>% nrow()
  } else if (cat == "Serious AE") {
    adae %>% filter(TRT01P == trt, AESER == "Y") %>% distinct(USUBJID) %>% nrow()
  } else if (cat == "Severe AE") {
    adae %>% filter(TRT01P == trt, AESEV == "SEVERE") %>% distinct(USUBJID) %>% nrow()
  } else if (cat == "Related AE") {
    adae %>% filter(TRT01P == trt, AREL == "RELATED") %>% distinct(USUBJID) %>% nrow()
  } else if (cat == "Leading to Disc.") {
    adae %>% filter(TRT01P == trt, AEACN == "DRUG WITHDRAWN") %>% distinct(USUBJID) %>% nrow()
  } else if (cat == "Fatal") {
    adae %>% filter(TRT01P == trt, AEOUT == "FATAL") %>% distinct(USUBJID) %>% nrow()
  } else {
    0
  }
  
  N <- n_per_trt %>% filter(TRT01P == trt) %>% pull(N)
  ae_incidence$n[i] <- n_subj
  ae_incidence$pct[i] <- n_subj / N * 100
}

# Create bar chart
p <- ggplot(ae_incidence, aes(x = Category, y = pct, fill = TRT01P)) +
  geom_bar(stat = "identity", position = "dodge", width = 0.7) +
  geom_text(aes(label = sprintf("%.1f%%", pct)), 
            position = position_dodge(width = 0.7), 
            vjust = -0.5, size = 3) +
  labs(
    title = "Adverse Event Incidence by Treatment Group",
    subtitle = "Safety Population",
    x = "AE Category",
    y = "Percentage of Subjects (%)",
    fill = "Treatment",
    caption = glue("Generated: {Sys.Date()}")
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    plot.subtitle = element_text(size = 11),
    axis.title = element_text(size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10),
    legend.position = "bottom"
  ) +
  scale_fill_brewer(palette = "Set1") +
  ylim(0, max(ae_incidence$pct) * 1.15)

# Save figure
save_figure(p, "Figure_14_2_AE_Incidence_Barchart", width = 10, height = 7)

cat("\n✓ AE incidence bar chart generation complete!\n\n")
