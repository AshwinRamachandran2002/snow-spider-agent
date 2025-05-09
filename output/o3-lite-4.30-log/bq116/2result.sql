WITH annual_revenue AS (
  SELECT
    q.submission_number,
    s.stprba,
    q.value,
    ROW_NUMBER() OVER (
      PARTITION BY q.submission_number
      ORDER BY CASE
                 WHEN q.measure_tag = 'SalesRevenueNet'        THEN 1
                 WHEN q.measure_tag = 'SalesRevenueGoodsNet'   THEN 2
                 WHEN q.measure_tag = 'Revenues'               THEN 3
                 ELSE 4
               END
    ) AS rn
  FROM `bigquery-public-data.sec_quarterly_financials.quick_summary` AS q
  JOIN `bigquery-public-data.sec_quarterly_financials.submission` AS s
    ON q.submission_number = s.submission_number
  WHERE q.fiscal_year = 2016
    AND q.number_of_quarters = 4
    AND q.measure_tag IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
    AND q.units = 'USD'
    AND q.value IS NOT NULL
    AND s.countryba = 'US'          -- keep only U.S. registrants
    AND s.stprba IS NOT NULL
    AND s.stprba != ''
)
SELECT
  stprba,
  ROUND(SUM(value) / 1e9, 4) AS total_annual_revenue_billions_usd
FROM annual_revenue
WHERE rn = 1                      -- one revenue figure per company
GROUP BY stprba
ORDER BY total_annual_revenue_billions_usd DESC
LIMIT 1;