WITH all_hits AS (
  -- All page hits in Jan-2017 sessions whose campaign contains “Data Share”
  SELECT
    fullVisitorId,
    visitId,
    h.hitNumber,
    h.page.pagePath AS pagePath,
    h.time
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`,
       UNNEST(hits) AS h
  WHERE LOWER(trafficSource.campaign) LIKE '%data share%'
    AND h.type = 'PAGE'
),
home_events AS (
  -- “/home…” page-views and the very next page in the same session
  SELECT
    pagePath                                                                    AS home_path,
    time                                                                        AS home_time,
    LEAD(pagePath) OVER(PARTITION BY fullVisitorId, visitId ORDER BY hitNumber) AS next_path,
    LEAD(time)     OVER(PARTITION BY fullVisitorId, visitId ORDER BY hitNumber) AS next_time
  FROM all_hits
  WHERE pagePath LIKE '/home%'
),
summary AS (
  -- Aggregate by the next page
  SELECT
    next_path,
    COUNT(*)                               AS visits_after_home,
    MAX( (next_time - home_time)/1000 )    AS max_time_spent_sec   -- seconds
  FROM home_events
  WHERE next_path IS NOT NULL
  GROUP BY next_path
)
-- Most common next page and max dwell time on “/home…”
SELECT
  next_path        AS most_common_next_page,
  max_time_spent_sec
FROM summary
ORDER BY visits_after_home DESC
LIMIT 1;