WITH jan17_hits AS (
  -- Page‑view hits in Jan‑2017 sessions whose campaign contains “Data Share”
  SELECT
    s.fullVisitorId,
    s.visitId,
    h.hitNumber,
    h.time                                   AS hit_time,          -- ms after visitStartTime
    h.page.pagePath                          AS page_path
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` AS s
  CROSS JOIN UNNEST(s.hits) AS h
  WHERE
        s.date BETWEEN '20170101' AND '20170131'
    AND LOWER(IFNULL(s.trafficSource.campaign, '')) LIKE '%data share%'
    AND h.type = 'PAGE'                                    -- keep only page hits
    AND h.page.pagePath IS NOT NULL
),
sequenced AS (
  -- For every hit, grab the next page and its timestamp
  SELECT
    fullVisitorId,
    visitId,
    page_path,
    hit_time,
    LEAD(page_path) OVER (PARTITION BY fullVisitorId, visitId ORDER BY hitNumber) AS next_page,
    LEAD(hit_time)  OVER (PARTITION BY fullVisitorId, visitId ORDER BY hitNumber) AS next_hit_time
  FROM jan17_hits
)
-- Most common next page after a “/home…” view, plus max dwell time on that /home page
SELECT
  next_page                    AS most_common_next_page,
  MAX( (next_hit_time - hit_time) / 1000 ) AS max_time_on_home_seconds
FROM sequenced
WHERE
      page_path LIKE '/home%'      -- current hit is a /home page
  AND next_page IS NOT NULL        -- there is a subsequent page
GROUP BY next_page
ORDER BY COUNT(*) DESC, next_page   -- most frequent first
LIMIT 1;