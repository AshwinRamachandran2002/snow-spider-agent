/*  Most common page visited after a “/home…” page and the maximum time
    spent on that “/home…” page by users whose campaign contains
    'Data Share' during January‑2017                                       */
WITH jan_sessions AS (
  SELECT
    fullVisitorId,
    visitId,
    hits
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`
  WHERE LOWER(trafficSource.campaign) LIKE '%data share%'        -- visitors of interest
    AND date BETWEEN '20170101' AND '20170131'                   -- January‑2017
),

page_hits AS (                                                   -- keep only PAGE hits
  SELECT
    fullVisitorId,
    visitId,
    h.hitNumber,
    h.time,                                                     -- ms after visitStartTime
    h.page.pagePath AS page_path
  FROM jan_sessions
  CROSS JOIN UNNEST(hits) AS h
  WHERE h.type = 'PAGE'
),

sequenced AS (                                                   -- look ahead to next PAGE
  SELECT
    fullVisitorId,
    visitId,
    hitNumber,
    page_path,
    time,
    LEAD(page_path) OVER (PARTITION BY fullVisitorId, visitId
                          ORDER BY hitNumber)    AS next_page,
    LEAD(time)      OVER (PARTITION BY fullVisitorId, visitId
                          ORDER BY hitNumber)    AS next_time
  FROM page_hits
),

home_transitions AS (                                            -- only “/home…” -> next
  SELECT
    next_page,
    (next_time - time) / 1000 AS time_on_home_sec               -- seconds on “/home…”
  FROM sequenced
  WHERE page_path LIKE '/home%'                                  -- current page
    AND next_page IS NOT NULL                                    -- must have a next page
)

SELECT
  -- (1) page most commonly visited after “/home…”
  (SELECT next_page
   FROM home_transitions
   GROUP BY next_page
   ORDER BY COUNT(*) DESC, next_page
   LIMIT 1)                                    AS most_common_next_page,

  -- (2) maximum time spent on a “/home…” page before moving on
  (SELECT MAX(time_on_home_sec)
   FROM home_transitions)                      AS max_time_on_home_sec;