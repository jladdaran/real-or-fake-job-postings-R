{\rtf1\ansi\ansicpg1252\cocoartf2822
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx566\tx1133\tx1700\tx2267\tx2834\tx3401\tx3968\tx4535\tx5102\tx5669\tx6236\tx6803\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # ===============================\
# 02_eda.R\
# ===============================\
\
library(dplyr); library(ggplot2); library(janitor); library(corrplot)\
\
df_us <- readRDS("data/processed/us_job_postings.rds")\
\
# Fraud distribution\
p1 <- ggplot(df_us, aes(x = fraudulent)) +\
  geom_bar() + ggtitle("Distribution of Real vs Fake Job Postings")\
dir.create("reports/figures", showWarnings = FALSE, recursive = TRUE)\
ggsave("reports/figures/fraud_distribution.png", p1, width=6, height=4, dpi=150)\
\
# Telecommuting by fraud\
if (all(c("telecommuting","fraudulent") %in% names(df_us))) \{\
  p2 <- ggplot(df_us, aes(x=telecommuting, fill=fraudulent)) +\
    geom_bar(position="dodge") + ggtitle("Telecommuting vs Fraudulence")\
  ggsave("reports/figures/telecommuting_by_fraud.png", p2, width=6, height=4, dpi=150)\
\}\
\
# State counts + fraud cross-tab\
tab_state <- tabyl(df_us, State, fraudulent)\
write.csv(tab_state, "reports/state_by_fraud.csv", row.names = FALSE)\
\
# Simple correlation on selected binaries\
num_cols <- intersect(c("telecommuting","has_company_logo","has_questions"), names(df_us))\
if (length(num_cols) >= 2) \{\
  M <- cor(sapply(df_us[num_cols], function(x) as.numeric(as.character(x))), use="pairwise.complete.obs")\
  png("reports/figures/corr.png", 800, 600)\
  corrplot(M, method="shade", addshade="all", addCoef.col="black")\
  dev.off()\
\}\
}