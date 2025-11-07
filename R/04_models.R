# 04_models.R\
# Models: KNN, SVM, RF (text) + Naive Bayes (structured) + Neural Net (structured)\
# ===============================\
\
# ---- Packages ----\
pkgs <- c("caret","e1071","pROC","gains","neuralnet","nnet")\
to_install <- setdiff(pkgs, rownames(installed.packages()))\
if (length(to_install)) install.packages(to_install, repos = "https://cloud.r-project.org")\
lapply(pkgs, library, character.only = TRUE)\
\
dir.create("reports/figures", showWarnings = FALSE, recursive = TRUE)\
dir.create("models", showWarnings = FALSE, recursive = TRUE)\
\
# ---- Load data from earlier steps ----\
# Text features (DTM-based, created in 03_text_prep.R)\
sdf_text <- readRDS("data/processed/text_sparse_df.rds")\
\
# Structured tabular data (created in 01_setup_and_load.R)\
df_us <- readRDS("data/processed/us_job_postings.rds")\
df_us$fraudulent <- as.factor(df_us$fraudulent)\
\
# ===============================\
# A) TEXT PIPELINE (DTM) \uc0\u8594  KNN, SVM, RF\
# ===============================\
set.seed(2020, sample.kind = "Rounding")\
idx_text <- createDataPartition(y = sdf_text$fraudulent, p = 0.1, list = FALSE)\
train_text <- sdf_text[-idx_text, ]\
valid_text <- sdf_text[idx_text, ]\
train_text$fraudulent <- as.factor(train_text$fraudulent)\
valid_text$fraudulent  <- as.factor(valid_text$fraudulent)\
\
ctrl <- trainControl(method = "cv", number = 5, verboseIter = TRUE)\
\
# KNN (text)\
knn_fit <- train(fraudulent ~ ., data = train_text, method = "knn",\
                 preProcess = c("center","scale"), trControl = ctrl,\
                 tuneGrid = expand.grid(k = c(5)))\
knn_pred <- predict(knn_fit, newdata = valid_text)\
cm_knn <- confusionMatrix(knn_pred, valid_text$fraudulent, mode = "everything")\
\
# SVM Linear (text)\
svm_fit <- train(fraudulent ~ ., data = train_text, method = "svmLinear",\
                 preProcess = c("center","scale"), trControl = ctrl,\
                 tuneGrid = expand.grid(C = c(0.01)))\
svm_pred <- predict(svm_fit, newdata = valid_text)\
cm_svm <- confusionMatrix(svm_pred, valid_text$fraudulent, mode = "everything")\
\
# Random Forest (text)\
rf_fit <- train(fraudulent ~ ., data = train_text, method = "rf",\
                ntree = 150, trControl = ctrl, tuneGrid = data.frame(mtry = min(100, max(2, floor(ncol(train_text)/3)))))\
rf_pred <- predict(rf_fit, newdata = valid_text)\
cm_rf <- confusionMatrix(rf_pred, valid_text$fraudulent, mode = "everything")\
saveRDS(rf_fit, "models/trained_model_text_rf.rds")\
\
# ===============================\
# B) STRUCTURED PIPELINE \uc0\u8594  Naive Bayes (+ ROC/AUC + Lift) & Neural Net\
# ===============================\
need_cols <- c("telecommuting","has_company_logo","has_questions",\
               "employment_type","required_experience","required_education","fraudulent")\
miss <- setdiff(need_cols, names(df_us))\
if (length(miss)) stop(paste("Missing required columns in df_us:", paste(miss, collapse=", ")))\
df_struct <- df_us[, need_cols]\
for (nm in setdiff(need_cols, "fraudulent")) df_struct[[nm]] <- as.factor(df_struct[[nm]])\
\
# One-hot encode\
X <- model.matrix(~ telecommuting + has_company_logo + has_questions +\
                    employment_type + required_experience + required_education - 1,\
                  data = df_struct)\
y <- df_struct$fraudulent\
df_nb <- as.data.frame(X); df_nb$fraudulent <- y\
\
# Split 70/30\
set.seed(2); n <- nrow(df_nb)\
train_index <- sample(seq_len(n), size = floor(0.7 * n))\
valid_index <- setdiff(seq_len(n), train_index)\
train_nb <- df_nb[train_index, ]; valid_nb <- df_nb[valid_index, ]\
\
# Naive Bayes\
nb_fit <- naiveBayes(fraudulent ~ ., data = train_nb)\
saveRDS(nb_fit, "models/trained_model_nb_structured.rds")\
\
nb_proba_valid <- predict(nb_fit, newdata = valid_nb, type = "raw")\
nb_pred_valid  <- predict(nb_fit, newdata = valid_nb, type = "class")\
nb_pred_train  <- predict(nb_fit, newdata = train_nb, type = "class")\
cm_nb_train <- confusionMatrix(nb_pred_train, train_nb$fraudulent, mode = "everything")\
cm_nb_valid <- confusionMatrix(nb_pred_valid, valid_nb$fraudulent, mode = "everything")\
\
# ROC / AUC (positive = level 2)\
pos_level <- levels(valid_nb$fraudulent)[2]; if (is.na(pos_level)) pos_level <- "1"\
if (!(pos_level %in% colnames(nb_proba_valid))) pos_level <- tail(colnames(nb_proba_valid), 1)\
nb_scores <- nb_proba_valid[, pos_level]\
roc_obj <- pROC::roc(response = as.numeric(valid_nb$fraudulent == levels(valid_nb$fraudulent)[2]),\
                     predictor = nb_scores)\
auc_nb <- pROC::auc(roc_obj)\
png("reports/figures/roc_naive_bayes.png", 800, 600)\
plot(roc_obj, col = "blue", main = sprintf("Naive Bayes ROC (AUC = %.3f)", as.numeric(auc_nb)))\
dev.off()\
\
# Lift\
gain_obj <- gains::gains(as.numeric(valid_nb$fraudulent == levels(valid_nb$fraudulent)[2]),\
                         nb_scores, groups = 10)\
png("reports/figures/lift_naive_bayes.png", 800, 600)\
plot(c(0, gain_obj$cume.pct.of.total * sum(valid_nb$fraudulent == levels(valid_nb$fraudulent)[2])) ~\
       c(0, gain_obj$cume.obs),\
     xlab = "# cases", ylab = "Cumulative", main = "Lift Chart (Naive Bayes)", type = "l")\
lines(c(0, sum(valid_nb$fraudulent == levels(valid_nb$fraudulent)[2])) ~\
        c(0, nrow(valid_nb)), lty = 2)\
dev.off()\
\
# Neural Net (two-output)\
y01 <- as.numeric(df_struct$fraudulent == levels(df_struct$fraudulent)[2])\
Y2 <- cbind(fraud_no = 1 - y01, fraud_yes = y01)\
df_nn <- as.data.frame(X); df_nn <- cbind(df_nn, Y2)\
train_nn <- df_nn[train_index, ]; valid_nn <- df_nn[valid_index, ]\
feature_cols <- setdiff(colnames(df_nn), c("fraud_no","fraud_yes"))\
fml <- as.formula(paste("fraud_no + fraud_yes ~", paste(feature_cols, collapse = " + ")))\
set.seed(2)\
nn_fit <- neuralnet::neuralnet(fml, data = train_nn, linear.output = FALSE, hidden = c(3,2), stepmax = 1e+07)\
nn_train_pred <- neuralnet::compute(nn_fit, train_nn[, feature_cols])$net.result\
nn_valid_pred <- neuralnet::compute(nn_fit, valid_nn[, feature_cols])$net.result\
train_class <- apply(nn_train_pred, 1, which.max) - 1\
valid_class <- apply(nn_valid_pred, 1, which.max) - 1\
cm_nn_train <- caret::confusionMatrix(factor(train_class),\
                                      factor(as.numeric(df_struct$fraudulent[train_index] == levels(df_struct$fraudulent)[2])),\
                                      mode = "everything")\
cm_nn_valid <- caret::confusionMatrix(factor(valid_class),\
                                      factor(as.numeric(df_struct$fraudulent[valid_index] == levels(df_struct$fraudulent)[2])),\
                                      mode = "everything")\
saveRDS(nn_fit, "models/trained_model_struct_nn.rds")\
\
# Save metrics\
sink("reports/metrics.txt")\
cat("=== TEXT MODELS (DTM) ===\\n")\
cat("\\n[KNN]\\n"); print(cm_knn)\
cat("\\n[SVM Linear]\\n"); print(cm_svm)\
cat("\\n[Random Forest]\\n"); print(cm_rf)\
cat("\\n\\n=== STRUCTURED MODELS ===\\n")\
cat("\\n[Naive Bayes] TRAIN\\n"); print(cm_nb_train)\
cat("\\n[Naive Bayes] VALID\\n"); print(cm_nb_valid)\
cat(sprintf("\\nNaive Bayes AUC (valid): %.4f\\n", as.numeric(auc_nb)))\
cat("\\n[Neural Net] TRAIN\\n"); print(cm_nn_train)\
cat("\\n[Neural Net] VALID\\n"); print(cm_nn_valid)\
sink()\
\
message("Done. Metrics saved to reports/metrics.txt; ROC/Lift plots saved to reports/figures/.")\
}
