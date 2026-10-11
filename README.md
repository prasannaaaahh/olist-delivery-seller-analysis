# Olist: Delivery and Seller Reliability Analysis

An end-to-end e-commerce analytics project using MySQL, Python and Power BI to investigate why deliveries are late, what lateness costs, and which sellers can be trusted.

## Business problem

Olist is a Brazilian online marketplace. It does not own the stock or the trucks, but its brand depends on sellers shipping quickly and carriers delivering on time. Operations leadership could not see how big the lateness problem is, whether it comes from sellers, carriers or unrealistic delivery promises, or which sellers deserve trust. This project answers those questions for the Head of Marketplace Operations and the Seller Success team.

## Key findings

- **6.78%** of valid deliveries arrived late (6,531 of 96,281). Late rates spiked to 12.4% in Nov 2017 and 19.0% in Mar 2018, against a normal 3-7%.
- **Carrier transit explains about 87%** of the extra delivery time on late orders; seller handling explains about 13%.
- Late orders average **2.27 stars vs 4.29** for on-time orders, a large effect. About 4 in 5 orders more than a week late get a 1-2 star review.
- Late rates vary by state and rise with distance: Alagoas has the highest rate (21.4%), while Rio de Janeiro has the most late orders (22.9% of all late orders).
- First-time customers whose order arrived late came back less often (about 3.0% vs 4.1%), but the direct repeat-purchase loss is small; the larger cost is in reviews.
- A seller reliability score (50% on-time rate, 30% handling speed, 20% reviews) groups the 626 sellers with 30+ orders into **Reliable (376), Watch (157) and At risk (93)** tiers. The tiering is stable under five alternative weightings.
- These are observational findings, not proof that lateness alone caused lower reviews or fewer repeat purchases.

## Dashboard

The Power BI report (`powerbi/olist_dashboard.pbix`) contains four pages:

1. **Overview**: order volume, revenue, order status and delivery trends.
2. **Delivery performance**: late rates by state, handling vs transit time, and category comparisons.
3. **Customer impact**: review scores and repeat-purchase rates by delivery performance.
4. **Seller scorecard**: seller reliability scores, tiers and comparisons.

## Tools

- MySQL and MySQL Workbench
- Python: pandas, NumPy, SciPy, SQLAlchemy, PyMySQL, matplotlib, seaborn
- Jupyter Notebook
- Power BI Desktop

## Data

- **Source:** [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) on Kaggle, licensed CC BY-NC-SA 4.0.
- The anonymised dataset covers about 99,000 orders from 2016-2018 across 9 tables.
- The raw CSV files are not included in this repository. Download them from Kaggle and place the nine CSV files in `data/raw/`.
- The Power BI file contains a processed extract of the data and carries the same licence. This project is for non-commercial portfolio use.

## How to reproduce

### Requirements

Install Python 3.10 or later, MySQL 8 or later, MySQL Workbench and Power BI Desktop.

### Setup

1. Download the dataset from Kaggle and place the CSV files in `data/raw/`.
2. Create the database using `sql/00_setup.sql`.
3. Create a `.env` file in the project root with your MySQL connection details:

   ```env
   DB_USER=your_mysql_user
   DB_PASSWORD=your_password
   DB_HOST=localhost
   DB_PORT=3306
   DB_NAME=olist
   ```

4. Create a virtual environment and install the dependencies:

   ```bash
   python -m venv venv
   ```

   On Windows:

   ```bash
   venv\Scripts\activate
   ```

   Then install the packages:

   ```bash
   pip install -r requirements.txt
   ```

5. Run these in order:
   1. `notebooks/01_load_data.ipynb`
   2. `notebooks/02_data_quality_log.ipynb`
   3. `sql/00_views.sql` (run in MySQL Workbench)
   4. `notebooks/03_delivery_analysis.ipynb`
   5. `notebooks/04_seller_score_and_impact.ipynb`
   6. `notebooks/05_build_powerbi_feed.ipynb`
6. Open `powerbi/olist_dashboard.pbix` in Power BI Desktop.

## Repository structure

```text
sql/          Database setup, views, analysis queries, and Power BI views
notebooks/    Data loading, quality checks, analysis, seller scoring, and exports
powerbi/      Power BI report, screenshots, and seller scores
docs/         Data-quality outputs and figures
requirements.txt
```

## Limitations

- The dataset covers 2016-2018 and is observational, so results show associations rather than causation.
- Carrier identifiers and delivery-cost data are not available.
- Distance is estimated as straight-line distance between postal-code-prefix centres.
- Seller scores are calculated only for sellers with at least 30 delivered orders.
- Late orders are defined as delivered on a calendar day after the promised day, using 96,281 valid deliveries (96.8% of all orders).

For detailed data-quality decisions, metric definitions, SQL query descriptions, statistical tests and additional results, see the notebooks and SQL files in the repository.
