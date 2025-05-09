WITH revenue_by_submission AS (
  SELECT
    n.submission_number,
    s.stprba AS state,
    n.value,
    ROW_NUMBER() OVER (
      PARTITION BY n.submission_number
      ORDER BY n.value DESC
    ) AS rn
  FROM `bigquery-public-data.sec_quarterly_financials.numbers` AS n
  JOIN `bigquery-public-data.sec_quarterly_financials.submission` AS s
    ON n.submission_number = s.submission_number
  WHERE n.measure_tag IN ('Revenues','SalesRevenueNet','SalesRevenueGoodsNet')
    AND n.units = 'USD'
    AND n.number_of_quarters = 4          -- full‑year amount
    AND n.dimension_hash = '0x00000000'   -- no dimensions (consolidated)
    AND n.num_dimensions = 0
    AND n.iprx = 0                        -- highest‑priority fact
    AND s.countryba = 'US'                -- U.S. filers only
    AND s.stprba IS NOT NULL
    AND s.stprba != ''
    AND s.fiscal_year = 2016              -- fiscal year 2016
    AND s.fiscal_period_focus = 'FY'      -- annual report
    AND s.form = '10-K'                   -- 10‑K filings
),
revenue_per_state AS (
  SELECT
    state,
    SUM(value) / 1e9 AS total_revenue_billions
  FROM revenue_by_submission
  WHERE rn = 1                            -- one revenue figure per company
  GROUP BY state
)
SELECT
  state,
  total_revenue_billions
FROM revenue_per_state
ORDER BY total_revenue_billions DESC
LIMIT 1;