WITH rev_by_state AS (
  SELECT
    s.stprba AS state,
    SUM(q.value) / 1e9 AS total_revenue_billions
  FROM
    `bigquery-public-data.sec_quarterly_financials.quick_summary` AS q
  JOIN
    `bigquery-public-data.sec_quarterly_financials.submission` AS s
  USING (submission_number)
  WHERE
    q.fiscal_year = 2016
    AND q.number_of_quarters = 4
    AND q.measure_tag IN ('Revenues', 'SalesRevenueNet', 'SalesRevenueGoodsNet')
    AND s.stprba IS NOT NULL
    AND s.stprba <> ''
  GROUP BY
    state
)
SELECT
  state,
  total_revenue_billions
FROM
  rev_by_state
ORDER BY
  total_revenue_billions DESC
LIMIT 1;