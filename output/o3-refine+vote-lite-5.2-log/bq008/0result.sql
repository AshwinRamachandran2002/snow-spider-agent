--  Most common page viewed after any “/home” page (January‑2017, campaign contains ‘Data Share’)
--  and the maximum seconds users spent on that “/home” page before moving on
WITH jan17 AS (
  SELECT
    fullVisitorId,
    visitId,
    hits.hitNumber                                   AS hit_number,
    hits.time                                        AS hit_time,          -- milliseconds after visitStartTime
    hits.page.pagePath                               AS page_path,
    trafficSource.campaign                           AS campaign
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`,
       UNNEST(hits) AS hits
  WHERE LOWER(trafficSource.campaign) LIKE '%data share%'        -- campaign filter
),
home_hits AS (
  SELECT
    fullVisitorId,
    visitId,
    hit_number,
    hit_time,
    page_path,
    LEAD(page_path) OVER (PARTITION BY fullVisitorId, visitId ORDER BY hit_number)
        AS next_page,
    LEAD(hit_time) OVER (PARTITION BY fullVisitorId, visitId ORDER BY hit_number)
        AS next_hit_time
  FROM jan17
  WHERE page_path LIKE '/home%'                                   -- pages that start with “/home”
),
transitions AS (
  SELECT
    next_page,
    (next_hit_time - hit_time)/1000.0 AS time_on_home_sec         -- convert ms → seconds
  FROM home_hits
  WHERE next_page IS NOT NULL                                     -- exclude last hit of session
)
SELECT
  next_page                    AS most_common_next_page,
  MAX(time_on_home_sec)        AS max_time_on_home_sec
FROM transitions
GROUP BY next_page
ORDER BY COUNT(*) DESC           -- most common
LIMIT 1;