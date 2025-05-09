-- Which U.S. state reported the highest total FY‑2016 revenue?
WITH revenue_base AS (
  SELECT
    n.submission_number,
    s.stprba                                                    AS state,
    n.measure_tag,
    n.value / 1e9                                               AS rev_billions,
    CASE n.measure_tag
         WHEN 'Revenues'               THEN 1
         WHEN 'SalesRevenueNet'        THEN 2
         WHEN 'SalesRevenueGoodsNet'   THEN 3
    END                                                        AS tag_priority
  FROM `bigquery-public-data.sec_quarterly_financials.numbers`     AS n
  JOIN `bigquery-public-data.sec_quarterly_financials.submission`  AS s
    ON n.submission_number = s.submission_number
  WHERE n.measure_tag IN ('Revenues','SalesRevenueNet','SalesRevenueGoodsNet')
    AND n.number_of_quarters = 4          -- full‑year data only
    AND s.fiscal_year = 2016              -- fiscal year 2016
    AND s.stprba IS NOT NULL
    AND s.stprba <> ''                    -- ignore missing states
    AND n.num_dimensions = 0              -- consolidated value
    AND (n.coregistrant IS NULL OR n.coregistrant = '')
),

-- for submissions that report more than one of the revenue tags,
-- keep just the highest‑priority tag (Revenues ≺ SalesRevenueNet ≺ SalesRevenueGoodsNet)
chosen_revenue AS (
  SELECT
    submission_number,
    state,
    rev_billions
  FROM (
    SELECT
      revenue_base.*,
      ROW_NUMBER() OVER (PARTITION BY submission_number
                         ORDER BY tag_priority) AS rn
    FROM revenue_base
  )
  WHERE rn = 1
)

SELECT
  state,
  ROUND(SUM(rev_billions),4) AS total_revenue_billions
FROM chosen_revenue
GROUP BY state
ORDER BY total_revenue_billions DESC
LIMIT 1;