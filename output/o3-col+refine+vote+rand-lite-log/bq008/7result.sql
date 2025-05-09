WITH home_hits AS (
  SELECT
    LEAD(h.page.pagePath) OVER w                              AS next_page,
    SAFE_DIVIDE(LEAD(h.time) OVER w - h.time, 1000)           AS seconds_on_home
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
       UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
    AND LOWER(trafficSource.campaign) LIKE '%data share%'
    AND h.type = 'PAGE'
    AND h.page.pagePath LIKE '/home%'
  WINDOW w AS (PARTITION BY fullVisitorId, visitId ORDER BY h.hitNumber)
),
agg AS (
  SELECT
    next_page,
    COUNT(*) AS visits_after_home,
    MAX(seconds_on_home) AS max_seconds_on_home
  FROM home_hits
  WHERE next_page IS NOT NULL
  GROUP BY next_page
)
SELECT
  next_page AS most_common_next_page,
  visits_after_home,
  max_seconds_on_home
FROM agg
ORDER BY visits_after_home DESC
LIMIT 1;