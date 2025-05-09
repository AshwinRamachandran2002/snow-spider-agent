-- U.S. state with the highest total FY‑2016 revenue (in billions)
WITH filings AS (
  SELECT
    s.submission_number,
    s.central_index_key  AS cik,
    s.stprba,
    ROW_NUMBER() OVER (PARTITION BY s.central_index_key ORDER BY s.date_filed DESC) AS rn
  FROM `bigquery-public-data.sec_quarterly_financials.submission` s
  WHERE s.fiscal_year = 2016                 -- fiscal year 2016
    AND s.stprba IS NOT NULL                -- state present
    AND s.stprba <> ''                      -- not empty string
),

latest_filings AS (                          -- keep latest FY‑2016 filing per company
  SELECT submission_number, cik, stprba
  FROM filings
  WHERE rn = 1
),

revenue_facts AS (
  SELECT
    lf.stprba,
    n.value                                   -- revenue in USD
  FROM latest_filings            AS lf
  JOIN `bigquery-public-data.sec_quarterly_financials.numbers` n
    ON n.submission_number = lf.submission_number
  WHERE n.measure_tag IN ('Revenues','SalesRevenueNet','SalesRevenueGoodsNet')
    AND n.units = 'USD'
    AND n.number_of_quarters = 4             -- four‑quarter (annual) data
    AND n.num_dimensions = 0                 -- consolidated (no dimensions)
    AND n.iprx = 0                           -- highest‑priority fact
)

SELECT
  stprba                                 AS state,
  SUM(value) / 1e9                       AS total_revenue_billions
FROM revenue_facts
GROUP BY state
ORDER BY total_revenue_billions DESC
LIMIT 1;