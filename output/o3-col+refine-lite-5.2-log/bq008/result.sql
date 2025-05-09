/*  In January‑2017, find
    1) the page most frequently visited right after a page that starts with '/home'
       (for sessions whose campaign contains 'Data Share')
    2) the maximum time (in seconds) users spent on that '/home' page
*/
WITH january_sessions AS (
  SELECT *
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`
  WHERE LOWER(trafficSource.campaign) LIKE '%data share%'
),

home_page_hits AS (
  SELECT
    s.fullVisitorId,
    s.visitId,
    h.hitNumber,
    h.page.pagePath                                                     AS pagePath,
    LEAD(h.page.pagePath) OVER(PARTITION BY s.fullVisitorId, s.visitId
                               ORDER BY h.hitNumber)                    AS next_page,
    SAFE_DIVIDE(                                                       -- time difference in seconds
      LEAD(h.time) OVER(PARTITION BY s.fullVisitorId, s.visitId
                        ORDER BY h.hitNumber) - h.time, 
      1000)                                                            AS time_spent_seconds
  FROM january_sessions AS s,
       UNNEST(s.hits)     AS h
  WHERE h.page.pagePath LIKE '/home%'                                   -- only '/home' (and sub‑paths)
),

transition_stats AS (                                                  -- most common next page
  SELECT
    COALESCE(next_page,'') AS next_page_path,
    COUNT(*)               AS transitions
  FROM home_page_hits
  GROUP BY next_page_path
  ORDER BY transitions DESC
  LIMIT 1
),

max_time_stat AS (                                                     -- maximum time on '/home'
  SELECT MAX(time_spent_seconds) AS max_time_seconds
  FROM home_page_hits
)

SELECT
  t.next_page_path  AS most_common_next_page,
  m.max_time_seconds
FROM transition_stats t
CROSS JOIN max_time_stat m;