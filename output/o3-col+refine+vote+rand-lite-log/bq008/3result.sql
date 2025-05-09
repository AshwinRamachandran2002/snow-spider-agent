-- Most common next page after any “/home…” page and
-- the maximum seconds spent on “/home…” before leaving,
-- for January-2017 sessions whose campaign contains “Data Share”
WITH hits_flat AS (
  SELECT
    fullVisitorId,
    visitId,
    h.hitNumber,
    h.time,
    h.page.pagePath,
    ROW_NUMBER() OVER
      (PARTITION BY fullVisitorId, visitId
       ORDER BY h.time, h.hitNumber) AS rn
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`,
       UNNEST(hits) AS h
  WHERE LOWER(trafficSource.campaign) LIKE '%data share%'          -- campaign filter
    AND h.type = 'PAGE'                                            -- keep only page hits
),
seq AS (
  SELECT
    LEAD(pagePath) OVER
      (PARTITION BY fullVisitorId, visitId ORDER BY rn)            AS next_page,
    SAFE_DIVIDE(
      LEAD(time) OVER
        (PARTITION BY fullVisitorId, visitId ORDER BY rn) - time,
      1000)                                                        AS seconds_on_home
  FROM hits_flat
  WHERE pagePath LIKE '/home%'                                     -- only “/home…” pages
)
SELECT
  next_page                      AS most_common_next_page,
  MAX(seconds_on_home)           AS max_seconds_before_next
FROM seq
WHERE next_page IS NOT NULL
GROUP BY next_page
ORDER BY COUNT(*) DESC           -- most common first
LIMIT 1;