WITH ranked_revenue AS (
  SELECT
    s.stprba AS state,
    n.value AS revenue_usd,
    ROW_NUMBER() OVER (
      PARTITION BY n.submission_number
      ORDER BY
        CASE n.measure_tag
          WHEN 'Revenues'               THEN 1
          WHEN 'SalesRevenueNet'        THEN 2
          WHEN 'SalesRevenueGoodsNet'   THEN 3
          ELSE 4
        END,
        n.iprx
    ) AS rn
  FROM `bigquery-public-data.sec_quarterly_financials.numbers`     AS n
  JOIN `bigquery-public-data.sec_quarterly_financials.submission`  AS s
    ON n.submission_number = s.submission_number
  WHERE n.measure_tag IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
    AND n.number_of_quarters = 4           -- full‑year figure
    AND n.units = 'USD'                    -- monetary values
    AND s.fiscal_year = 2016               -- fiscal year 2016
    AND s.stprba IS NOT NULL               -- valid state
    AND s.stprba <> ''
)

SELECT
  state,
  SUM(revenue_usd) / 1e9 AS total_revenue_billions
FROM ranked_revenue
WHERE rn = 1                               -- one revenue figure per company
GROUP BY state
ORDER BY total_revenue_billions DESC
LIMIT 1;