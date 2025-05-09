-- Most–common next page after any “/home…” view and the maximum time
-- spent on that home page for Jan-2017 sessions whose campaign
-- contains “Data Share”
WITH sessions_jan17 AS (
  SELECT
    fullVisitorId,
    visitId,
    hits.hitNumber                         AS hit_num,
    hits.time                              AS hit_time_ms,
    hits.page.pagePath                     AS page_path
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`,
       UNNEST(hits) AS hits
  WHERE LOWER(trafficSource.campaign) LIKE '%data share%'     -- campaign filter
    AND hits.type = 'PAGE'                                    -- keep only PAGE hits
),

seq AS (
  SELECT
    fullVisitorId,
    visitId,
    page_path                                 AS current_page,
    LEAD(page_path)  OVER sess_w              AS next_page,
    (LEAD(hit_time_ms) OVER sess_w - hit_time_ms) / 1000.0
                                               AS time_spent_sec        -- secs on current_page
  FROM sessions_jan17
  WINDOW sess_w AS (PARTITION BY fullVisitorId, visitId ORDER BY hit_num)
)

SELECT
  next_page                  AS most_common_next_page,
  COUNT(*)                   AS transition_count,
  MAX(time_spent_sec)        AS max_time_spent_sec
FROM seq
WHERE current_page LIKE '/home%'      -- only transitions from “/home…”
  AND next_page IS NOT NULL
GROUP BY next_page
ORDER BY transition_count DESC
LIMIT 1;