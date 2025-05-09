WITH ordered_hits AS (
  -- every PAGE hit in Jan‑2017 sessions whose campaign contains 'Data Share'
  SELECT
    fullVisitorId,
    visitId,
    h.hitNumber                                       AS hit_num,
    h.time                                            AS hit_time_ms,
    h.page.pagePath                                   AS page_path,
    LEAD(h.page.pagePath) OVER(PARTITION BY fullVisitorId, visitId ORDER BY h.hitNumber)  AS next_page_path,
    LEAD(h.time)        OVER(PARTITION BY fullVisitorId, visitId ORDER BY h.hitNumber)  AS next_hit_time_ms
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`  s,
       UNNEST(s.hits) AS h
  WHERE LOWER(s.trafficSource.campaign) LIKE '%data share%'   -- visitors from a “Data Share” campaign
    AND h.type = 'PAGE'
),
home_transitions AS (
  -- keep only hits whose pagePath starts with '/home' (any case) and that actually have a next page
  SELECT
    next_page_path,
    (next_hit_time_ms - hit_time_ms) / 1000 AS time_on_home_sec          -- seconds spent on /home page
  FROM ordered_hits
  WHERE REGEXP_CONTAINS(LOWER(page_path), r'^/home')                      -- page begins with “/home”
    AND next_page_path IS NOT NULL
),
top_next AS (
  -- most‑frequent next page after visiting a /home page
  SELECT
    next_page_path,
    COUNT(*) AS visits
  FROM home_transitions
  GROUP BY next_page_path
  ORDER BY visits DESC
  LIMIT 1
)
SELECT
  t.next_page_path           AS most_common_next_page,
  MAX(h.time_on_home_sec)    AS max_time_on_home_seconds
FROM top_next AS t
JOIN home_transitions AS h
ON h.next_page_path = t.next_page_path
GROUP BY t.next_page_path;