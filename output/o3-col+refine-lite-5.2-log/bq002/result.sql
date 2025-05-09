/*  Top‑performing traffic‑source in H1‑2017 and its max daily / weekly / monthly
    product‑revenue figures (all amounts already divided by 1e6 → “millions”).   */

WITH sales AS (    -- every product‑revenue hit in H1‑2017
  SELECT
    trafficSource.source                                           AS source,
    PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)                            AS day,
    hp.productRevenue / 1e6                                        AS product_rev_mln
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
        UNNEST(hits)    AS h,
        UNNEST(h.product) AS hp
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170630'
    AND hp.productRevenue IS NOT NULL
),

top_source AS (    -- traffic‑source with the highest total product revenue
  SELECT   source,
           SUM(product_rev_mln) AS total_rev_mln
  FROM     sales
  GROUP BY source
  ORDER BY total_rev_mln DESC
  LIMIT    1
),

daily AS (
  SELECT source,
         day,
         SUM(product_rev_mln) AS daily_rev_mln
  FROM   sales
  WHERE  source IN (SELECT source FROM top_source)
  GROUP  BY source, day
),

weekly AS (
  SELECT source,
         FORMAT_DATE('%G-W%V', day) AS iso_week,
         SUM(product_rev_mln)      AS week_rev_mln
  FROM   sales
  WHERE  source IN (SELECT source FROM top_source)
  GROUP  BY source, iso_week
),

monthly AS (
  SELECT source,
         FORMAT_DATE('%Y-%m', day) AS month,
         SUM(product_rev_mln)     AS month_rev_mln
  FROM   sales
  WHERE  source IN (SELECT source FROM top_source)
  GROUP  BY source, month
)

SELECT
  ts.source                              AS top_source,
  ts.total_rev_mln                       AS h1_total_rev_mln,
  (SELECT MAX(daily_rev_mln)  FROM daily)   AS max_daily_rev_mln,
  (SELECT MAX(week_rev_mln)   FROM weekly)  AS max_weekly_rev_mln,
  (SELECT MAX(month_rev_mln)  FROM monthly) AS max_monthly_rev_mln
FROM top_source AS ts;