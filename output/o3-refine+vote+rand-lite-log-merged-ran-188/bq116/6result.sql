WITH per_filer AS (
  SELECT
    s.`stprba`                       AS state,
    q.`submission_number`,
    MAX(q.`value`)                   AS annual_revenue_usd          -- pick one annual figure per filer
  FROM `bigquery-public-data.sec_quarterly_financials.quick_summary` AS q
  JOIN `bigquery-public-data.sec_quarterly_financials.submission`    AS s
    ON q.`submission_number` = s.`submission_number`
  WHERE
        q.`fiscal_year` = 2016
    AND q.`measure_tag` IN ('Revenues','SalesRevenueNet','SalesRevenueGoodsNet')
    AND q.`number_of_quarters` = 4                                   -- need full-year data
    AND s.`stprba` IS NOT NULL
    AND s.`stprba` <> ''                                              -- exclude blank states
  GROUP BY state, q.`submission_number`
)

SELECT
  state,
  ROUND(SUM(annual_revenue_usd) / 1e9, 2) AS total_revenue_2016_billions
FROM per_filer
GROUP BY state
ORDER BY total_revenue_2016_billions DESC
LIMIT 1;