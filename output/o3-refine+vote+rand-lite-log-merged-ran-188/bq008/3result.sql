-- Most common page visited after "/home" and the maximum
-- time (in seconds) users spent on "/home" before navigating away.
WITH session_hits AS (
  SELECT
    fullVisitorId,
    visitId,
    hits.hitNumber            AS hit_number,
    hits.time                 AS hit_time_ms,          -- milliseconds after visitStartTime
    hits.page.pagePath        AS page_path
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits
  WHERE
        _TABLE_SUFFIX BETWEEN '0101' AND '0131'          -- January 2017 tables
    AND LOWER(trafficSource.campaign) LIKE '%data share%' -- campaign contains "Data Share"
    AND hits.type = 'PAGE'                               -- only page‑view hits
),

home_views AS (                                              -- every "/home" view
  SELECT
    *,
    LEAD(page_path) OVER (PARTITION BY fullVisitorId, visitId
                          ORDER BY hit_number)                          AS next_page,
    (LEAD(hit_time_ms) OVER (PARTITION BY fullVisitorId, visitId
                             ORDER BY hit_number) - hit_time_ms) / 1000 AS time_spent_sec
  FROM session_hits
  WHERE page_path LIKE '/home%'                                   -- pages starting with "/home"
)

SELECT
  next_page                 AS next_page_path,
  COUNT(*)                  AS views_after_home,
  MAX(time_spent_sec)       AS max_time_spent_on_home_sec
FROM home_views
WHERE next_page IS NOT NULL                                       -- keep only if another page followed
GROUP BY next_page
ORDER BY views_after_home DESC, next_page_path
LIMIT 1;