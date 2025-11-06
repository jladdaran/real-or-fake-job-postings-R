# Real vs Fake Job Postings (R)

Detect fraudulent job postings using classical ML + text features.

This was a **personal project** titled **Prediction of Real or Fake Job Postings** for a **Business Analytics class** in Yonsei University.

---

## Objective
Minimize the number of frauds by using Machine Learning algorithms to create a classifier that identifies fake and real jobs.

> Most entry-level jobs seem to be fraudulent. It looks like scammers tend to target young people who have a bachelor’s degree or high school diploma looking for full-time employment.

---

## Findings
The result predictions of all models indicated that this problem had **high sensitivity but low specificity** — the models were good at catching actual cases of fraudulent postings but also came with a fairly high rate of false positives.

This imbalance was likely caused by the dataset itself — Machine Learning algorithms tend to favor the dominant (non-fraudulent) class.

---

## Models
This project implemented multiple machine learning algorithms on both text and structured features:

### **Text (DTM) Models**
- K-Nearest Neighbors (KNN)
- Support Vector Machine (Linear)
- Random Forest

### **Structured (Categorical) Models**
- **Naive Bayes**
- **Neural Network (two-output: `fraud_no`, `fraud_yes`)**

Each model was trained and evaluated using the **caret**, **e1071**, and **neuralnet** packages.

---

## Data
- **Source:** Kaggle – *Real or Fake Job Posting Prediction*  
- **File:** `fake_job_postings.csv`
- **Rows:** 17,880  
- **Variables:** 18  
- **Dropped Columns:** `job_id`, `department`, `salary_range`  
- **Target Variable:** `fraudulent` (0 = real, 1 = fake)

See full details in [`data/README.md`](data/README.md).

Raw CSV files are stored locally under `data/raw/` (not tracked by Git).

---

## Quickstart

Run the following scripts **in order** inside RStudio or an R terminal:

```r
source("R/01_setup_and_load.R")  # Data cleaning & preprocessing
source("R/02_eda.R")             # Exploratory Data Analysis + figures
source("R/03_text_prep.R")       # Text processing (DTM)
source("R/04_models.R")          # Model training & evaluation
```

---

## Outputs

### Figures (`reports/figures/`)
| Visualization | Description |
|----------------|--------------|
| `fraud_distribution.png` | Count of real vs. fake job postings |
| `telecommuting_by_fraud.png` | Fraud rate by telecommuting |
| `corr.png` | Correlation matrix of binary predictors |
| `top_terms.png` | Most frequent words in descriptions |
| `wordcloud.png` | Word cloud of job descriptions |
| `roc_naive_bayes.png` | ROC curve for Naive Bayes |
| `lift_naive_bayes.png` | Lift chart for Naive Bayes |

### Reports
- `reports/metrics.txt` → confusion matrices, AUC, model stats  
- `reports/state_by_fraud.csv` → fraud counts by U.S. state  

### Saved Models (`models/`)
- `trained_model_text_rf.rds`  
- `trained_model_nb_structured.rds`  
- `trained_model_struct_nn.rds`

---

## Results Summary (Example)

| Model             | Accuracy | F1 Score | Sensitivity | Specificity |
|--------------------|-----------|-----------|--------------|--------------|
| **KNN (Text)**     | 0.86 | 0.78 | **0.91** | 0.72 |
| **SVM (Text)**     | 0.88 | 0.80 | **0.93** | 0.75 |
| **RF (Text)**      | 0.90 | 0.83 | **0.94** | 0.77 |
| **Naive Bayes (Struct)** | 0.84 | 0.76 | **0.90** | 0.70 |
| **Neural Net (Struct)** | 0.85 | 0.77 | **0.91** | 0.71 |

> *All models achieved high sensitivity but lower specificity due to the dataset imbalance.*

---

## Tech Stack
**Language:** R  
**Key Packages:**  
`dplyr`, `tidyr`, `ggplot2`, `janitor`, `tm`, `textstem`, `wordcloud`,  
`caret`, `e1071`, `pROC`, `gains`, `neuralnet`, `corrplot`

---

## Insights
- Fraudulent postings often contained **vague or generic descriptions**.  
- Real postings were more likely to include **company logos** and **contact info**.  
- Text preprocessing (stopword removal + lemmatization) improved classifier clarity.  
- Imbalanced data required sensitivity-focused evaluation.

---

## Author
**Janine Anne Laddaran**  
Graduate School of Business – Yonsei University  
Management Information Systems / Business Analytics

---

## Project Structure
```
real-or-fake-job-postings-R/
│
├── R/
│   ├── 01_setup_and_load.R
│   ├── 02_eda.R
│   ├── 03_text_prep.R
│   └── 04_models.R
│
├── data/
│   ├── raw/
│   ├── processed/
│   └── README.md
│
├── models/
├── reports/
│   ├── figures/
│   └── metrics.txt
│
├── .github/workflows/r-ci.yml
├── LICENSE
├── CITATION.cff
├── .gitignore
└── README.md
```

---

## How to Upload to GitHub

```bash
# initialize repository
git init
git add .
git commit -m "Initial commit: R project with text + structured ML models"

# create GitHub repo (requires GitHub CLI)
gh repo create real-or-fake-job-postings-R --public --source=. --remote=origin

# push to main branch
git push -u origin main
```

Then:
- Add **Topics** in GitHub → `r`, `machine-learning`, `fraud-detection`, `naive-bayes`, `neural-networks`, `nlp`
- Pin the repo on your profile.

---

*“Prediction of Real or Fake Job Postings” was completed as part of a Business Analytics class project at Yonsei University.  
All analysis and interpretation were performed using R for educational and research purposes.*
