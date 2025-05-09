WITH
weeks_before AS (
  SELECT calendar_year, week_date,
         ROW_NUMBER() OVER (PARTITION BY calendar_year ORDER BY week_date DESC) AS rn
  FROM (
    SELECT DISTINCT calendar_year, week_date
    FROM "cleaned_weekly_sales"
    WHERE week_date < (calendar_year || '-06-15')
  )
),
weeks_after AS (
  SELECT calendar_year, week_date,
         ROW_NUMBER() OVER (PARTITION BY calendar_year ORDER BY week_date ASC) AS rn
  FROM (
    SELECT DISTINCT calendar_year, week_date
    FROM "cleaned_weekly_sales"
    WHERE week_date > (calendar_year || '-06-15')
  )
),
weeks_before_top4 AS (
  SELECT calendar_year, week_date
  FROM weeks_before
  WHERE rn <= 4
),
weeks_after_top4 AS (
  SELECT calendar_year, week_date
  FROM weeks_after
  WHERE rn <= 4
),
before_sales AS (
  SELECT calendar_year, SUM(sales) AS total_sales_before
  FROM "cleaned_weekly_sales"
  WHERE (calendar_year, week_date) IN (SELECT calendar_year, week_date FROM weeks_before_top4)
  GROUP BY calendar_year
),
after_sales AS (
  SELECT calendar_year, SUM(sales) AS total_sales_after
  FROM "cleaned_weekly_sales"
  WHERE (calendar_year, week_date) IN (SELECT calendar_year, week_date FROM weeks_after_top4)
  GROUP BY calendar_year
)
SELECT 
  before_sales.calendar_year AS "Year",
  ROUND(
    ((after_sales.total_sales_after - before_sales.total_sales_before) * 100.0 / before_sales.total_sales_before),
    4
  ) AS "Percentage_Change_Sales"
FROM before_sales
JOIN after_sales ON before_sales.calendar_year = after_sales.calendar_year
ORDER BY "Year" ASC;