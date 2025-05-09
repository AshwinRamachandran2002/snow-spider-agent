WITH revenue_facts AS (
  SELECT
    q.submission_number,
    q.value,                         -- reported revenue value
    q.measure_tag,
    s.stprba AS state                -- U.S. state of business address
  FROM `bigquery-public-data.sec_quarterly_financials.quick_summary`   AS q
  JOIN `bigquery-public-data.sec_quarterly_financials.submission`      AS s
    ON q.submission_number = s.submission_number
  WHERE q.measure_tag IN ('Revenues','SalesRevenueNet','SalesRevenueGoodsNet')
    AND q.number_of_quarters = 4            -- full‑year amount
    AND s.fiscal_year        = 2016         -- fiscal year 2016
    AND s.countryba          = 'US'         -- U.S. registrants only
    AND s.stprba IS NOT NULL
    AND s.stprba != ''                      -- exclude missing states
    AND q.units              = 'USD'        -- keep comparable currency
),
-- keep only one revenue figure per submission, preferring 'Revenues' first
deduplicated AS (
  SELECT
    submission_number,
    state,
    value,
    ROW_NUMBER() OVER (
      PARTITION BY submission_number
      ORDER BY CASE measure_tag
                 WHEN 'Revenues'             THEN 1
                 WHEN 'SalesRevenueNet'      THEN 2
                 WHEN 'SalesRevenueGoodsNet' THEN 3
                 ELSE 4
               END
    ) AS rn
  FROM revenue_facts
)
SELECT
  state,
  SUM(value) / 1e9 AS total_revenue_billions
FROM deduplicated
WHERE rn = 1                      -- one revenue figure per company/year
GROUP BY state
ORDER BY total_revenue_billions DESC
LIMIT 1;