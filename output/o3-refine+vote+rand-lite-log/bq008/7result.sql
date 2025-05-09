-- Most common page visited immediately after a “/home*” page
-- by visitors whose campaign contains “Data Share” in January‑2017,
-- together with the maximum time (in seconds) they stayed on the
-- “/home” page before moving on.

WITH jan17 AS (
  -- sessions in January‑2017 with campaign containing 'Data Share'
  SELECT
    fullVisitorId,
    visitId,
    hits.hitNumber,
    hits.time                    AS hit_time_ms,
    hits.page.pagePath           AS page_path
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`,
       UNNEST(hits) AS hits
  WHERE trafficSource.campaign LIKE '%Data Share%'          -- campaign filter
    AND hits.type = 'PAGE'                                  -- keep only page hits
),

sequenced AS (
  -- add next page and its time within the same session
  SELECT
    fullVisitorId,
    visitId,
    page_path                         AS current_page,
    hit_time_ms                       AS current_time_ms,
    LEAD(page_path) OVER (PARTITION BY fullVisitorId, visitId
                          ORDER BY hitNumber)               AS next_page,
    LEAD(hit_time_ms) OVER (PARTITION BY fullVisitorId, visitId
                            ORDER BY hitNumber)             AS next_time_ms
  FROM jan17
)

SELECT
  next_page                                              AS most_common_next_page,
  MAX( (next_time_ms - current_time_ms) / 1000 ) AS max_time_on_home_sec
FROM sequenced
WHERE current_page LIKE '/home%'         -- only transitions leaving “/home*”
  AND next_page IS NOT NULL
GROUP BY next_page
ORDER BY COUNT(*) DESC                  -- most common next page
LIMIT 1;