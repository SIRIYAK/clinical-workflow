# ==============================================================================
# OFS (Output for Submission) Package Preparation
# Script: prepare_ofs.R
# Purpose: Prepare complete submission package with all outputs
# ==============================================================================

source("R/setup/00_install_packages.R")
source("R/setup/01_config.R")
source("R/setup/02_utilities.R")

cat("\n========================================\n")
cat("OFS Package Preparation\n")
cat("========================================\n\n")

# ==============================================================================
# Create OFS Directory Structure
# ==============================================================================

cat("Creating OFS directory structure...\n")

ofs_dirs <- c(
  "outputs/ofs/datasets/sdtm",
  "outputs/ofs/datasets/adam",
  "outputs/ofs/define",
  "outputs/ofs/tlf/tables",
  "outputs/ofs/tlf/listings",
  "outputs/ofs/tlf/figures",
  "outputs/ofs/adrg",
  "outputs/ofs/documentation"
)

for (dir in ofs_dirs) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    cat(glue("  Created: {dir}\n"))
  }
}

# ==============================================================================
# Copy SDTM Datasets (XPT only for submission)
# ==============================================================================

cat("\nCopying SDTM datasets...\n")

sdtm_xpt_files <- list.files(PATHS$sdtm, pattern = "\\.xpt$", full.names = TRUE)

for (file in sdtm_xpt_files) {
  dest_file <- file.path("outputs/ofs/datasets/sdtm", basename(file))
  file.copy(file, dest_file, overwrite = TRUE)
  cat(glue("  ✓ Copied: {basename(file)}\n"))
}

cat(glue("Total SDTM datasets: {length(sdtm_xpt_files)}\n"))

# ==============================================================================
# Copy ADaM Datasets (XPT only for submission)
# ==============================================================================

cat("\nCopying ADaM datasets...\n")

adam_xpt_files <- list.files(PATHS$adam, pattern = "\\.xpt$", full.names = TRUE)

for (file in adam_xpt_files) {
  dest_file <- file.path("outputs/ofs/datasets/adam", basename(file))
  file.copy(file, dest_file, overwrite = TRUE)
  cat(glue("  ✓ Copied: {basename(file)}\n"))
}

cat(glue("Total ADaM datasets: {length(adam_xpt_files)}\n"))

# ==============================================================================
# Copy TLF Outputs
# ==============================================================================

cat("\nCopying TLF outputs...\n")

# Tables
if (dir.exists("outputs/tlf/tables")) {
  table_files <- list.files("outputs/tlf/tables", pattern = "\\.(rtf|docx)$", full.names = TRUE)
  for (file in table_files) {
    dest_file <- file.path("outputs/ofs/tlf/tables", basename(file))
    file.copy(file, dest_file, overwrite = TRUE)
  }
  cat(glue("  ✓ Copied {length(table_files)} tables\n"))
}

# Listings
if (dir.exists("outputs/tlf/listings")) {
  listing_files <- list.files("outputs/tlf/listings", pattern = "\\.rtf$", full.names = TRUE)
  for (file in listing_files) {
    dest_file <- file.path("outputs/ofs/tlf/listings", basename(file))
    file.copy(file, dest_file, overwrite = TRUE)
  }
  cat(glue("  ✓ Copied {length(listing_files)} listings\n"))
}

# Figures
if (dir.exists("outputs/tlf/figures")) {
  figure_files <- list.files("outputs/tlf/figures", pattern = "\\.(png|pdf|tiff)$", full.names = TRUE)
  for (file in figure_files) {
    dest_file <- file.path("outputs/ofs/tlf/figures", basename(file))
    file.copy(file, dest_file, overwrite = TRUE)
  }
  cat(glue("  ✓ Copied {length(figure_files)} figures\n"))
}

# ==============================================================================
# Generate OFS Index
# ==============================================================================

cat("\nGenerating OFS index...\n")

ofs_index <- tibble::tibble(
  Category = character(),
  Subcategory = character(),
  Filename = character(),
  Description = character(),
  File_Size_KB = numeric(),
  Date_Created = character()
)

# SDTM datasets
for (file in sdtm_xpt_files) {
  ofs_index <- ofs_index %>%
    bind_rows(tibble::tibble(
      Category = "Datasets",
      Subcategory = "SDTM",
      Filename = basename(file),
      Description = toupper(tools::file_path_sans_ext(basename(file))),
      File_Size_KB = round(file.size(file) / 1024, 2),
      Date_Created = as.character(file.info(file)$mtime)
    ))
}

# ADaM datasets
for (file in adam_xpt_files) {
  ofs_index <- ofs_index %>%
    bind_rows(tibble::tibble(
      Category = "Datasets",
      Subcategory = "ADaM",
      Filename = basename(file),
      Description = toupper(tools::file_path_sans_ext(basename(file))),
      File_Size_KB = round(file.size(file) / 1024, 2),
      Date_Created = as.character(file.info(file)$mtime)
    ))
}

# Export index
index_file <- "outputs/ofs/OFS_Index.xlsx"
writexl::write_xlsx(ofs_index, index_file)
cat(glue("  ✓ Index saved: {basename(index_file)}\n"))

# ==============================================================================
# Generate OFS README
# ==============================================================================

cat("\nGenerating OFS README...\n")

readme_content <- glue("
# Output for Submission (OFS) Package

## Study Information
- Study ID: {STUDY_CONFIG$study_id}
- Protocol: {STUDY_CONFIG$protocol}
- Sponsor: {STUDY_CONFIG$sponsor}
- Indication: {STUDY_CONFIG$indication}
- Phase: {STUDY_CONFIG$phase}

## Package Contents

### Datasets
- **SDTM**: {length(sdtm_xpt_files)} domains (CDISC SDTM v{STUDY_CONFIG$sdtm_version})
- **ADaM**: {length(adam_xpt_files)} datasets (CDISC ADaM v{STUDY_CONFIG$adam_version})

All datasets are in SAS Transport (XPT) v5 format.

### Tables, Listings, and Figures (TLF)
- Tables: Located in `tlf/tables/`
- Listings: Located in `tlf/listings/`
- Figures: Located in `tlf/figures/`

### Documentation
- Dataset specifications: See `define/` directory
- Analysis Results Metadata: See `adrg/` directory

## Directory Structure

```
ofs/
├── datasets/
│   ├── sdtm/          # SDTM XPT files
│   └── adam/          # ADaM XPT files
├── define/            # Define.xml files
├── tlf/
│   ├── tables/        # Statistical tables (RTF/DOCX)
│   ├── listings/      # Data listings (RTF)
│   └── figures/       # Figures (PNG/PDF/TIFF)
├── adrg/              # Analysis Results Metadata
├── documentation/     # Additional documentation
└── OFS_Index.xlsx     # Complete file inventory
```

## Standards Compliance
- CDISC SDTM v{STUDY_CONFIG$sdtm_version}
- CDISC ADaM v{STUDY_CONFIG$adam_version}
- CDISC Controlled Terminology {STUDY_CONFIG$cdisc_ct_version}
- ICH E3 Guidelines

## Generation Information
- Generated: {Sys.Date()}
- Framework Version: 1.0.0

## Contact
For questions regarding this submission package, please contact:
{STUDY_CONFIG$sponsor}
")

readme_file <- "outputs/ofs/README.md"
writeLines(readme_content, readme_file)
cat(glue("  ✓ README saved: {basename(readme_file)}\n"))

# ==============================================================================
# Summary
# ==============================================================================

cat("\n========================================\n")
cat("OFS Package Summary\n")
cat("========================================\n\n")

cat("Package Location: outputs/ofs/\n\n")

cat("Contents:\n")
cat(sprintf("  SDTM Datasets: %d\n", length(sdtm_xpt_files)))
cat(sprintf("  ADaM Datasets: %d\n", length(adam_xpt_files)))

if (exists("table_files")) cat(sprintf("  Tables: %d\n", length(table_files)))
if (exists("listing_files")) cat(sprintf("  Listings: %d\n", length(listing_files)))
if (exists("figure_files")) cat(sprintf("  Figures: %d\n", length(figure_files)))

total_size <- sum(file.size(list.files("outputs/ofs", recursive = TRUE, full.names = TRUE)), na.rm = TRUE)
cat(sprintf("\nTotal Package Size: %.2f MB\n", total_size / 1024 / 1024))

cat("\n✓ OFS package preparation complete!\n")
cat("========================================\n\n")
