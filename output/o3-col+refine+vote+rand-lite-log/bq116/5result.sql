-- Highest-revenue U.S. state in FY-2016
SELECT state,
       total_revenue_billion
FROM (
  SELECT
    s.stprba AS state,
    SUM(n.value) / 1e9 AS total_revenue_billion
  FROM `bigquery-public-data.sec_quarterly_financials.numbers`    AS n
  JOIN `bigquery-public-data.sec_quarterly_financials.submission` AS s
    ON n.submission_number = s.submission_number
  WHERE n.measure_tag IN ('Revenues','SalesRevenueNet','SalesRevenueGoodsNet')
    AND n.number_of_quarters = 4          -- full-year figures
    AND s.fiscal_year = 2016              -- fiscal year 2016
    AND s.stprba IS NOT NULL              -- keep only rows with a state
    AND s.stprba <> ''
  GROUP BY state
  ORDER BY total_revenue_billion DESC
  LIMIT 1
);