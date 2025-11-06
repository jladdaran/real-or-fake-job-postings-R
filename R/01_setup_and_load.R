{\rtf1\ansi\ansicpg1252\cocoartf2822
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx566\tx1133\tx1700\tx2267\tx2834\tx3401\tx3968\tx4535\tx5102\tx5669\tx6236\tx6803\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # ===============================\
# 01_setup_and_load.R\
# ===============================\
\
# Load necessary libraries (auto-install if missing)\
pkgs <- c(\
  "dplyr","tidyr","stringr","ggplot2","janitor","corrplot",\
  "tm","textstem","wordcloud","wordcloud2","RColorBrewer",\
  "caret","syuzhet"\
)\
to_install <- setdiff(pkgs, rownames(installed.packages()))\
if (length(to_install)) install.packages(to_install, repos = "https://cloud.r-project.org")\
lapply(pkgs, library, character.only = TRUE)\
\
# Data loading & cleaning\
df_raw <- read.csv("data/raw/fake_job_postings.csv", na.strings = "", stringsAsFactors = FALSE)\
\
# Split location into Country / State / City\
df <- df_raw %>% extract(location, c("Country","State","City"), "([^,]+), ([^)]+), ([^)]+)")\
\
# Replace NA with "MISSING"\
df[is.na(df)] <- "MISSING"\
\
# Remove unused columns if present\
drop_cols <- intersect(c("job_id","department","salary_range"), names(df))\
df <- df[, setdiff(names(df), drop_cols)]\
\
# Filter to US only and normalize State token\
df_us <- subset(df, Country == "US")\
df_us$State <- sub(",.*", "", df_us$State)\
\
# Factors\
for (nm in c("fraudulent","telecommuting","has_company_logo","has_questions")) \{\
  if (nm %in% names(df_us)) df_us[[nm]] <- factor(df_us[[nm]])\
\}\
\
# Quick class balance check\
print(df_us %>% count(fraudulent))\
\
# Save processed\
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)\
saveRDS(df_us, "data/processed/us_job_postings.rds")\
}