-- Top-performing traffic source in Jan-Jun 2017
--   + its MAX daily, weekly, and monthly product revenues (millions of $)

WITH base AS (           -- all product-revenue hits in H1-2017
  SELECT
    trafficSource.source                         AS source,
    date,
    hitProduct.productRevenue                    AS revenue_micro
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits)      AS h,
       UNNEST(h.product) AS hitProduct
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND hitProduct.productRevenue IS NOT NULL
),

top_source AS (          -- find the #1 revenue-generating source
  SELECT source
  FROM   base
  GROUP  BY source
  ORDER  BY SUM(revenue_micro) DESC
  LIMIT  1
),

daily_totals AS (        -- day-level totals for that source
  SELECT
    date,
    SUM(revenue_micro)/1e12 AS revenue_millions      -- micro → millions
  FROM   base
  JOIN   top_source USING (source)
  GROUP  BY date
),

weekly_totals AS (       -- ISO-week totals
  SELECT
    EXTRACT(ISOYEAR  FROM PARSE_DATE('%Y%m%d', date)) AS iso_year,
    EXTRACT(ISOWEEK FROM PARSE_DATE('%Y%m%d', date)) AS iso_week,
    SUM(revenue_micro)/1e12                          AS revenue_millions
  FROM   base
  JOIN   top_source USING (source)
  GROUP  BY iso_year, iso_week
),

monthly_totals AS (      -- month totals
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', date)) AS month,
    SUM(revenue_micro)/1e12                          AS revenue_millions
  FROM   base
  JOIN   top_source USING (source)
  GROUP  BY month
)

SELECT
  (SELECT source            FROM top_source)            AS top_performing_source,
  (SELECT MAX(revenue_millions) FROM daily_totals)      AS max_daily_revenue_millions,
  (SELECT MAX(revenue_millions) FROM weekly_totals)     AS max_weekly_revenue_millions,
  (SELECT MAX(revenue_millions) FROM monthly_totals)    AS max_monthly_revenue_millions