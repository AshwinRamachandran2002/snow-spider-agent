--  Most-frequent page that follows a “/home…” view (Jan-2017, Campaign contains “Data Share”)
WITH home_steps AS (       -- every /home PAGE hit & its successor inside the same session
  SELECT
    LEAD(h.page.pagePath) OVER win                       AS next_page,
    (LEAD(h.time) OVER win - h.time)/1000.0             AS diff_sec        -- dwell-time on /home (s)
  FROM  `bigquery-public-data.google_analytics_sample.ga_sessions_*`  AS s
  CROSS JOIN UNNEST(s.hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
    AND LOWER(s.trafficSource.campaign) LIKE '%data share%'
    AND h.type = 'PAGE'
    AND h.page.pagePath LIKE '/home%'                    -- current page is “/home…”
  WINDOW win AS (PARTITION BY s.fullVisitorId, s.visitId ORDER BY h.hitNumber)
),
next_pages AS (            -- aggregate transitions from /home → next_page
  SELECT
    next_page,
    COUNT(*)           AS transitions,
    MAX(diff_sec)      AS max_seconds_on_home
  FROM home_steps
  WHERE next_page IS NOT NULL
  GROUP BY next_page
),
ranked AS (                -- rank by how frequently each next_page occurs
  SELECT
    next_page,
    transitions,
    max_seconds_on_home,
    RANK() OVER (ORDER BY transitions DESC) AS rnk
  FROM next_pages
)
SELECT
  next_page                AS most_common_next_page,
  transitions              AS times_visited_next_page,
  max_seconds_on_home      AS max_time_spent_on_home_sec
FROM ranked
WHERE rnk = 1;