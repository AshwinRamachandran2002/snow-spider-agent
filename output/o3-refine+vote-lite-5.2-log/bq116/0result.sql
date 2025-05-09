-- Which U.S. state reported the highest total FY‑2016 revenue?
WITH annual_revenue AS (
  -- one (annual) revenue figure per filing
  SELECT
    n.submission_number,
    ARRAY_AGG(
        n.value
        ORDER BY CASE n.measure_tag
                   WHEN 'Revenues'            THEN 1
                   WHEN 'SalesRevenueNet'     THEN 2
                   WHEN 'SalesRevenueGoodsNet'THEN 3
                 END
        LIMIT 1
    )[OFFSET(0)] AS revenue_usd
  FROM `bigquery-public-data.sec_quarterly_financials.numbers` AS n
  WHERE n.measure_tag IN ('Revenues',
                          'SalesRevenueNet',
                          'SalesRevenueGoodsNet')
    AND n.number_of_quarters = 4          -- full‑year amount
    AND n.units = 'USD'                   -- monetary values only
  GROUP BY n.submission_number
),
fy2016_state_revenue AS (
  SELECT
    s.stprba AS state,
    ar.revenue_usd
  FROM `bigquery-public-data.sec_quarterly_financials.submission` AS s
  JOIN annual_revenue AS ar
    ON s.submission_number = ar.submission_number
  WHERE s.fiscal_year = 2016              -- fiscal year 2016
    AND s.countryba = 'US'                -- U.S. companies only
    AND s.stprba IS NOT NULL
    AND TRIM(s.stprba) <> ''              -- exclude blank states
)
SELECT
  state,
  SUM(revenue_usd) / 1e9 AS total_revenue_billions
FROM fy2016_state_revenue
GROUP BY state
ORDER BY total_revenue_billions DESC
LIMIT 1;