/*  State with the highest aggregated FY‑2016 revenue                              */
/*  – uses annual (4‑quarter) revenue facts tagged as Revenues / SalesRevenue…    */

WITH fy16_revenue AS (
  SELECT
    sub.stprba AS state,
    qs.value            AS revenue_usd
  FROM `bigquery-public-data.sec_quarterly_financials.quick_summary`  qs
  JOIN `bigquery-public-data.sec_quarterly_financials.submission`     sub
        ON sub.submission_number = qs.submission_number
  WHERE
        qs.measure_tag IN ('Revenues','SalesRevenueNet','SalesRevenueGoodsNet')
    AND qs.number_of_quarters = 4                -- full‑year amount
    AND sub.fiscal_year       = 2016             -- FY 2016
    AND sub.stprba IS NOT NULL
    AND sub.stprba != ''
    AND qs.units = 'USD'
    AND qs.value IS NOT NULL
)

SELECT
  state,
  SUM(revenue_usd) / 1e9 AS total_revenue_billions
FROM fy16_revenue
GROUP BY state
ORDER BY total_revenue_billions DESC
LIMIT 1;