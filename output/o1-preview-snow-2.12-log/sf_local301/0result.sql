WITH sales_data AS (
  SELECT
    TO_DATE("week_date", 'DD/MM/YY') AS "week_date",
    "sales",
    EXTRACT(YEAR FROM TO_DATE("week_date", 'DD/MM/YY')) AS "Year",
    CASE
      WHEN EXTRACT(YEAR FROM TO_DATE("week_date", 'DD/MM/YY')) = 2018 AND TO_DATE("week_date", 'DD/MM/YY') BETWEEN '2018-05-21' AND '2018-06-11' THEN 'Before'
      WHEN EXTRACT(YEAR FROM TO_DATE("week_date", 'DD/MM/YY')) = 2018 AND TO_DATE("week_date", 'DD/MM/YY') BETWEEN '2018-06-18' AND '2018-07-09' THEN 'After'
      WHEN EXTRACT(YEAR FROM TO_DATE("week_date", 'DD/MM/YY')) = 2019 AND TO_DATE("week_date", 'DD/MM/YY') BETWEEN '2019-05-20' AND '2019-06-10' THEN 'Before'
      WHEN EXTRACT(YEAR FROM TO_DATE("week_date", 'DD/MM/YY')) = 2019 AND TO_DATE("week_date", 'DD/MM/YY') BETWEEN '2019-06-17' AND '2019-07-08' THEN 'After'
      WHEN EXTRACT(YEAR FROM TO_DATE("week_date", 'DD/MM/YY')) = 2020 AND TO_DATE("week_date", 'DD/MM/YY') BETWEEN '2020-05-18' AND '2020-06-08' THEN 'Before'
      WHEN EXTRACT(YEAR FROM TO_DATE("week_date", 'DD/MM/YY')) = 2020 AND TO_DATE("week_date", 'DD/MM/YY') BETWEEN '2020-06-15' AND '2020-07-06' THEN 'After'
      ELSE NULL
    END AS "Period"
  FROM BANK_SALES_TRADING.BANK_SALES_TRADING.WEEKLY_SALES
  WHERE EXTRACT(YEAR FROM TO_DATE("week_date", 'DD/MM/YY')) IN (2018, 2019, 2020)
),
aggregated_sales AS (
  SELECT
    "Year",
    "Period",
    SUM("sales") AS "total_sales"
  FROM sales_data
  WHERE "Period" IS NOT NULL
  GROUP BY "Year", "Period"
),
sales_totals AS (
  SELECT
    "Year",
    SUM(CASE WHEN "Period" = 'Before' THEN "total_sales" ELSE 0 END) AS "before_sales",
    SUM(CASE WHEN "Period" = 'After' THEN "total_sales" ELSE 0 END) AS "after_sales"
  FROM aggregated_sales
  GROUP BY "Year"
)
SELECT
  "Year",
  ROUND((("after_sales" - "before_sales") / ("before_sales" * 1.0)) * 100, 4) AS "Percentage_Change"
FROM sales_totals
ORDER BY "Year";