WITH annual_revenue AS (
  SELECT
    qs.submission_number,
    qs.value,
    ROW_NUMBER() OVER (
      PARTITION BY qs.submission_number
      ORDER BY CASE qs.measure_tag
                 WHEN 'Revenues'            THEN 1
                 WHEN 'SalesRevenueNet'     THEN 2
                 WHEN 'SalesRevenueGoodsNet'THEN 3
               END
    ) AS rn
  FROM `bigquery-public-data.sec_quarterly_financials.quick_summary` qs
  WHERE qs.measure_tag IN ('Revenues','SalesRevenueNet','SalesRevenueGoodsNet')
    AND qs.number_of_quarters = 4
    AND qs.fiscal_year = 2016
),
selected_revenue AS (
  SELECT submission_number, value
  FROM   annual_revenue
  WHERE  rn = 1          -- keep one revenue figure per filing
),
state_revenue AS (
  SELECT
    s.stprba                                AS state,
    SUM(sr.value) / 1e9                     AS total_revenue_billions
  FROM   selected_revenue sr
  JOIN   `bigquery-public-data.sec_quarterly_financials.submission` s
         USING (submission_number)
  WHERE  s.countryba = 'US'
    AND  s.stprba   IS NOT NULL
    AND  s.stprba  <> ''
  GROUP BY state
)
SELECT *
FROM   state_revenue
ORDER BY total_revenue_billions DESC
LIMIT 1;