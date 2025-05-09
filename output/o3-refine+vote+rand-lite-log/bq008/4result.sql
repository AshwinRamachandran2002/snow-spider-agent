WITH sessions AS (
  SELECT
    fullVisitorId,
    visitId,
    hits
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'                 -- January 2017
    AND REGEXP_CONTAINS(LOWER(trafficSource.campaign), r'data\s*share') -- campaign contains “Data Share”
),
hits_flat AS (
  SELECT
    fullVisitorId,
    visitId,
    h.hitNumber,
    h.time,
    h.page.pagePath AS pagePath
  FROM sessions
  CROSS JOIN UNNEST(hits) AS h
  WHERE h.type = 'PAGE'                                                 -- page‑view hits only
),
home_hits AS (                                                           -- /home page views
  SELECT
    LEAD(pagePath) OVER (PARTITION BY fullVisitorId, visitId ORDER BY hitNumber)              AS next_page_path,
    (LEAD(time) OVER (PARTITION BY fullVisitorId, visitId ORDER BY hitNumber) - time) / 1000  AS time_spent_sec
  FROM hits_flat
  WHERE pagePath LIKE '/home%'                                           -- current page starts with /home
)

SELECT
  next_page_path,
  MAX(time_spent_sec) AS max_time_seconds
FROM home_hits
WHERE next_page_path IS NOT NULL                                         -- exclude sessions ending on /home
GROUP BY next_page_path
ORDER BY COUNT(*) DESC                                                   -- most common next page first
LIMIT 1;