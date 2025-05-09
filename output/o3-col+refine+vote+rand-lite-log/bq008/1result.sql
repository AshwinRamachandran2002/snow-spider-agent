WITH hits_sequenced AS (
  SELECT
    h.page.pagePath                                            AS current_page,
    LEAD(h.page.pagePath) OVER w                               AS next_page,
    h.time                                                     AS current_time_ms,
    LEAD(h.time) OVER w                                        AS next_time_ms
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`,
        UNNEST(hits) AS h
  WHERE LOWER(trafficSource.campaign) LIKE '%data share%'
  WINDOW w AS (
    PARTITION BY fullVisitorId, visitId
    ORDER BY h.hitNumber
  )
),
home_transitions AS (
  SELECT
    next_page,
    (next_time_ms - current_time_ms) / 1000.0 AS time_on_home_sec
  FROM hits_sequenced
  WHERE current_page LIKE '/home%'        -- pages that start with '/home'
    AND next_page IS NOT NULL             -- keep only those with a following page
)
SELECT
  next_page            AS most_common_next_page,
  MAX(time_on_home_sec) AS max_time_on_home_sec
FROM home_transitions
GROUP BY next_page
ORDER BY COUNT(*) DESC          -- most common first
LIMIT 1;