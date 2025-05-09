WITH ranked_revenues AS (
  SELECT
    qs.submission_number,
    sub.stprba AS state,
    qs.value,
    ROW_NUMBER() OVER (
      PARTITION BY qs.submission_number
      ORDER BY
        CASE qs.measure_tag
          WHEN 'Revenues'            THEN 1
          WHEN 'SalesRevenueNet'     THEN 2
          WHEN 'SalesRevenueGoodsNet' THEN 3
          ELSE 4
        END
    ) AS rn
  FROM `bigquery-public-data.sec_quarterly_financials.quick_summary` qs
  JOIN `bigquery-public-data.sec_quarterly_financials.submission` sub
    ON qs.submission_number = sub.submission_number
  WHERE
    qs.fiscal_year = 2016                       -- fiscal year 2016
    AND qs.fiscal_period_focus = 'FY'           -- full‑year facts
    AND qs.number_of_quarters = 4               -- four‑quarter (annual) duration
    AND qs.measure_tag IN ('Revenues',
                           'SalesRevenueNet',
                           'SalesRevenueGoodsNet')
    AND sub.countryba = 'US'                    -- U.S. registrants
    AND sub.stprba IS NOT NULL
    AND sub.stprba <> ''
),
company_revenue AS (      -- keep one revenue figure per company
  SELECT
    state,
    value
  FROM ranked_revenues
  WHERE rn = 1
)
SELECT
  state,
  SUM(value) / 1e9 AS total_revenue_billions
FROM company_revenue
GROUP BY state
ORDER BY total_revenue_billions DESC
LIMIT 1;