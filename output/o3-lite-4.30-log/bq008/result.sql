WITH sessions AS (
  SELECT
    s.fullVisitorId,
    s.visitId,
    h.hitNumber,
    h.time,
    h.page.pagePath AS page_path
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*` AS s
  CROSS JOIN UNNEST(s.hits) AS h
  WHERE s.date BETWEEN '20170101' AND '20170131'
    AND LOWER(s.trafficSource.campaign) LIKE '%data share%'
),
home_hits AS (
  SELECT
    fullVisitorId,
    visitId,
    page_path                          AS home_path,
    LEAD(page_path) OVER w             AS next_path,
    time                               AS home_time,
    LEAD(time)      OVER w             AS next_time
  FROM sessions
  WHERE LOWER(page_path) LIKE '/home%'
  WINDOW w AS (PARTITION BY fullVisitorId, visitId ORDER BY hitNumber)
),
agg AS (
  SELECT
    next_path,
    COUNT(*) AS freq
  FROM home_hits
  WHERE next_path IS NOT NULL
  GROUP BY next_path
)
SELECT
  (SELECT next_path
     FROM agg
     ORDER BY freq DESC, next_path
     LIMIT 1)                                 AS next_page,
  ROUND(MAX((next_time - home_time)/1000), 4) AS max_time_on_home_seconds
FROM home_hits
WHERE next_path IS NOT NULL;