WITH seq AS (
  SELECT
    LEAD(h.page.pagePath) OVER (PARTITION BY s.fullVisitorId, s.visitId ORDER BY h.hitNumber) 
        AS next_page,
    (COALESCE(
        LEAD(h.time) OVER (PARTITION BY s.fullVisitorId, s.visitId ORDER BY h.hitNumber),
        s.totals.timeOnSite * 1000
     ) - h.time) / 1000.0                                        AS seconds_on_home
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s,
       UNNEST(s.hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'          -- January 2017
    AND LOWER(s.trafficSource.campaign) LIKE '%data share%'      -- campaign filter
    AND h.page.pagePath LIKE '/home%'                            -- pages starting with '/home'
),
agg AS (
  SELECT
    next_page,
    COUNT(*)                             AS cnt,
    MAX(seconds_on_home)                 AS max_time_on_home_seconds
  FROM seq
  WHERE next_page IS NOT NULL
  GROUP BY next_page
)
SELECT
  next_page,
  ROUND(max_time_on_home_seconds, 4)     AS max_time_on_home_seconds
FROM agg
ORDER BY cnt DESC, next_page
LIMIT 1;