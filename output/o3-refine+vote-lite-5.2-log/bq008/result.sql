/* Most‑common next page after a “/home*” page in Jan‑2017
   for sessions whose campaign name contains “Data Share”, and the
   maximum seconds spent on that “/home*” page before moving on.            */

WITH jan_sessions AS (   -- sessions in January 2017, campaign has “Data Share”
  SELECT
    fullVisitorId,
    visitId,
    hits
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
    AND LOWER(trafficSource.campaign) LIKE '%data share%'
),

page_hits AS (           -- keep only PAGE hits
  SELECT
    fullVisitorId,
    visitId,
    h.hitNumber                    AS hit_num,
    h.time                         AS hit_time,          -- ms after visitStartTime
    h.page.pagePath                AS page_path
  FROM jan_sessions
  CROSS JOIN UNNEST(hits) AS h
  WHERE h.type = 'PAGE'
),

home_with_next AS (       -- for each /home* hit, grab the next hit in the session
  SELECT
    fullVisitorId,
    visitId,
    page_path                       AS home_path,
    LEAD(page_path) OVER win        AS next_page,
    LEAD(hit_time)  OVER win        AS next_time,
    hit_time                        AS home_time
  FROM page_hits
  WINDOW win AS (PARTITION BY fullVisitorId, visitId ORDER BY hit_num)
)

SELECT
  next_page                                        AS most_common_next_page,
  MAX( (next_time - home_time) / 1000 )            AS max_seconds_on_home   -- seconds
FROM home_with_next
WHERE LOWER(home_path) LIKE '/home%'               -- only “/home*” pages
  AND next_page IS NOT NULL                        -- must have a following page
GROUP BY next_page
ORDER BY COUNT(*) DESC                             -- most frequent next page
LIMIT 1;