/*  Most common page that visitors (campaign name contains 'Data Share') go to
    after viewing any page that starts with '/home' in January‑2017,
    together with the maximum time (in seconds) they stayed on the
    '/home' page before moving on                                       */

WITH jan17_sessions AS (
  SELECT
    fullVisitorId,
    visitId,
    hits
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'       -- January 2017
    AND LOWER(trafficSource.campaign) LIKE '%data share%' -- campaign filter
),

all_hits AS (
  SELECT
    fullVisitorId,
    visitId,
    h.hitNumber,
    h.time           AS hit_time_ms,
    h.page.pagePath  AS page_path
  FROM
    jan17_sessions,
    UNNEST(hits) AS h
  WHERE
    h.type = 'PAGE'                                       -- keep only page‑view hits
),

home_hits AS (
  SELECT
    *,
    LEAD(page_path) OVER (PARTITION BY fullVisitorId, visitId ORDER BY hitNumber)     AS next_page,
    LEAD(hit_time_ms) OVER (PARTITION BY fullVisitorId, visitId ORDER BY hitNumber)   AS next_time_ms
  FROM
    all_hits
  WHERE
    page_path LIKE '/home%'                              -- current page is '/home...'
),

home_hits_next AS (
  SELECT
    next_page,
    (next_time_ms - hit_time_ms) / 1000.0 AS time_spent_seconds   -- convert ms → s
  FROM
    home_hits
  WHERE
    next_page IS NOT NULL
    AND next_time_ms > hit_time_ms                                -- keep sensible rows
)

SELECT
  /* most common next page */
  ( SELECT next_page
    FROM  ( SELECT next_page, COUNT(*) AS cnt
            FROM   home_hits_next
            GROUP  BY next_page
            ORDER  BY cnt DESC, next_page
            LIMIT  1 ) )              AS most_common_next_page,

  /* maximum time spent on a '/home' page before moving on */
  ( SELECT MAX(time_spent_seconds)
    FROM   home_hits_next )           AS max_time_on_home_seconds;