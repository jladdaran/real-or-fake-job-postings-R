# ===============================\
# 03_text_prep.R\
# ===============================\
\
library(tm); library(textstem); library(wordcloud); library(RColorBrewer)\
\
df_us <- readRDS("data/processed/us_job_postings.rds")\
stopifnot("description" %in% names(df_us))\
\
# Corpus build & clean\
corp <- Corpus(VectorSource(df_us$description))\
corp <- tm_map(corp, content_transformer(tolower))\
corp <- tm_map(corp, removePunctuation)\
corp <- tm_map(corp, removeWords, stopwords("english"))\
corp <- tm_map(corp, removeWords, c("the","andor","our","also","may","can","you","one","this","will"))\
corp <- tm_map(corp, stripWhitespace)\
\
# Lemmatize\
lemmatized <- lemmatize_words(sapply(corp, `[[`, "content"))\
corp_lem <- Corpus(VectorSource(lemmatized))\
\
# TDM \uc0\u8594  term frequency df\
dtm <- TermDocumentMatrix(corp_lem)\
m <- as.matrix(dtm)\
termfreq <- sort(rowSums(m), decreasing=TRUE)\
df_terms <- data.frame(word=names(termfreq), freq=termfreq)\
\
# Visuals\
dir.create("reports/figures", showWarnings = FALSE, recursive = TRUE)\
png("reports/figures/top_terms.png", 800, 600)\
barplot(df_terms[1:20,]$freq, las=2, names.arg=df_terms[1:20,]$word,\
        main="Most Frequent Words", ylab="Frequency", col="lightblue")\
dev.off()\
\
set.seed(123)\
png("reports/figures/wordcloud.png", 800, 600)\
wordcloud(words=df_terms$word, freq=df_terms$freq, max.words=200,\
          random.order=FALSE, rot.per=0.3, colors=brewer.pal(8,"Dark2"))\
dev.off()\
\
# ML matrix\
sparse_df <- as.data.frame(t(m))\
sparse_df <- setNames(sparse_df, make.names(colnames(sparse_df), unique=TRUE))\
sparse_df$fraudulent <- df_us$fraudulent\
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)\
saveRDS(sparse_df, "data/processed/text_sparse_df.rds")\
}
