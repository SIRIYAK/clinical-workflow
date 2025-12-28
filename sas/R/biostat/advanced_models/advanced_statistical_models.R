# ==============================================================================
# Advanced Statistical Models - MMRM and Mixed Models
# Script: advanced_statistical_models.R
# Purpose: Mixed Models for Repeated Measures (MMRM) and other advanced analyses
# ==============================================================================

source("R/setup/00_install_packages.R")

# Install additional packages
if (!require("nlme")) install.packages("nlme")
if (!require("lme4")) install.packages("lme4")
if (!require("emmeans")) install.packages("emmeans")
if (!require("lmerTest")) install.packages("lmerTest")

library(nlme)
library(lme4)
library(emmeans)
library(lmerTest)
library(dplyr)
library(ggplot2)

cat("\n========================================\n")
cat("Advanced Statistical Models\n")
cat("========================================\n\n")

# Read ADLB data
adlb <- haven::read_sas(file.path("data/adam", "adlb.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y", PARAMCD == "HGB", !is.na(AVAL))

cat(glue("Loaded {nrow(adlb)} records for analysis\n\n"))

# ==============================================================================
# 1. Mixed Model for Repeated Measures (MMRM)
# ==============================================================================

cat("[1] MMRM Analysis\n")
cat(strrep("-", 80), "\n")

# MMRM model: Change from baseline with unstructured covariance
mmrm_model <- lme(
  CHG ~ TRT01P * AVISIT + BASE,
  random = ~ 1 | USUBJID,
  correlation = corSymm(form = ~ 1 | USUBJID),
  weights = varIdent(form = ~ 1 | AVISIT),
  data = adlb,
  method = "REML",
  na.action = na.omit
)

cat("MMRM Model Summary:\n")
print(summary(mmrm_model))

# Extract LS Means
mmrm_emmeans <- emmeans(mmrm_model, ~ TRT01P | AVISIT)

cat("\n\nLS Means by Treatment and Visit:\n")
print(summary(mmrm_emmeans))

# Pairwise comparisons
mmrm_contrasts <- pairs(mmrm_emmeans, by = "AVISIT")

cat("\n\nPairwise Comparisons:\n")
print(summary(mmrm_contrasts))

# Export results
mmrm_results <- tibble(
  Visit = rep(levels(factor(adlb$AVISIT)), each = length(unique(adlb$TRT01P))),
  Treatment = rep(unique(adlb$TRT01P), length(unique(adlb$AVISIT))),
  LS_Mean = summary(mmrm_emmeans)$emmean,
  SE = summary(mmrm_emmeans)$SE,
  Lower_CI = summary(mmrm_emmeans)$lower.CL,
  Upper_CI = summary(mmrm_emmeans)$upper.CL
)

writexl::write_xlsx(mmrm_results, "outputs/biostat/MMRM_Results.xlsx")
cat("\n✓ MMRM results saved: outputs/biostat/MMRM_Results.xlsx\n\n")

# ==============================================================================
# 2. Linear Mixed Effects Model
# ==============================================================================

cat("[2] Linear Mixed Effects Model\n")
cat(strrep("-", 80), "\n")

# Random intercept and slope model
lme_model <- lmer(
  AVAL ~ TRT01P * ADY + BASE + (1 + ADY | USUBJID),
  data = adlb,
  REML = TRUE
)

cat("Linear Mixed Model Summary:\n")
print(summary(lme_model))

# Extract fixed effects
fixed_effects <- fixef(lme_model)
cat("\n\nFixed Effects:\n")
print(fixed_effects)

# Extract random effects variance
random_effects <- VarCorr(lme_model)
cat("\n\nRandom Effects Variance:\n")
print(random_effects)

# ==============================================================================
# 3. Generalized Linear Mixed Model (GLMM) for Binary Outcomes
# ==============================================================================

cat("\n[3] GLMM for Binary Outcomes\n")
cat(strrep("-", 80), "\n")

# Read ADAE for binary outcome example
adae <- haven::read_sas(file.path("data/adam", "adae.sas7bdat")) %>%
  tibble::as_tibble() %>%
  filter(SAFFL == "Y")

# Create binary outcome: Any Grade 3+ AE
adsl_ae <- adae %>%
  group_by(USUBJID, TRT01P) %>%
  summarise(
    Any_Grade3_AE = max(ATOXGRN >= 3, na.rm = TRUE),
    .groups = "drop"
  )

# GLMM with logit link
glmm_model <- glmer(
  Any_Grade3_AE ~ TRT01P + (1 | USUBJID),
  data = adsl_ae,
  family = binomial(link = "logit")
)

cat("GLMM Summary:\n")
print(summary(glmm_model))

# Calculate odds ratios
or_estimates <- exp(fixef(glmm_model))
cat("\n\nOdds Ratios:\n")
print(or_estimates)

# ==============================================================================
# 4. Repeated Measures ANOVA
# ==============================================================================

cat("\n[4] Repeated Measures ANOVA\n")
cat(strrep("-", 80), "\n")

# RM-ANOVA using nlme
rm_anova <- aov(AVAL ~ TRT01P * AVISIT + Error(USUBJID/AVISIT), data = adlb)

cat("Repeated Measures ANOVA:\n")
print(summary(rm_anova))

# ==============================================================================
# 5. Visualization of Model Results
# ==============================================================================

cat("\n[5] Visualizing Model Results\n")
cat(strrep("-", 80), "\n")

# Plot LS Means over time
p_lsmeans <- ggplot(mmrm_results, aes(x = Visit, y = LS_Mean, color = Treatment, group = Treatment)) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  geom_errorbar(aes(ymin = Lower_CI, ymax = Upper_CI), width = 0.2) +
  labs(
    title = "MMRM: LS Means Change from Baseline Over Time",
    subtitle = "With 95% Confidence Intervals",
    x = "Visit",
    y = "LS Mean Change from Baseline",
    color = "Treatment"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 14, face = "bold"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave("outputs/biostat/MMRM_LSMeans_Plot.png", p_lsmeans, width = 10, height = 6, dpi = 300)
cat("✓ LS Means plot saved: outputs/biostat/MMRM_LSMeans_Plot.png\n\n")

# ==============================================================================
# 6. Model Diagnostics
# ==============================================================================

cat("[6] Model Diagnostics\n")
cat(strrep("-", 80), "\n")

# Residual plots
png("outputs/biostat/MMRM_Diagnostics.png", width = 12, height = 8, units = "in", res = 300)
par(mfrow = c(2, 2))

# Residuals vs Fitted
plot(mmrm_model, main = "Residuals vs Fitted")

# Q-Q plot
qqnorm(resid(mmrm_model), main = "Normal Q-Q Plot")
qqline(resid(mmrm_model))

# Scale-Location
plot(mmrm_model, sqrt(abs(resid(.))) ~ fitted(.), main = "Scale-Location")

# Residuals vs Leverage
plot(mmrm_model, resid(.) ~ fitted(.), main = "Residuals vs Leverage")

dev.off()

cat("✓ Diagnostic plots saved: outputs/biostat/MMRM_Diagnostics.png\n\n")

cat("========================================\n")
cat("✓ Advanced statistical models complete!\n")
cat("========================================\n\n")
