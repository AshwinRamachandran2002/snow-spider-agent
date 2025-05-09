-- Most common page visited after “/home…” (Data-Share campaigns, Jan-2017)
-- …and the maximum time (secs) spent on “/home” before leaving it
WITH flat AS (
  SELECT
    h.page.pagePath                                           AS this_path,
    LEAD(h.page.pagePath) OVER(PARTITION BY s.fullVisitorId,
                                           s.visitId
                              ORDER BY h.hitNumber)           AS next_path,
    SAFE_DIVIDE(
      LEAD(h.time) OVER(PARTITION BY s.fullVisitorId,
                                    s.visitId
                         ORDER BY h.hitNumber) - h.time,
      1000)                                                   AS secs_on_home
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*` AS s
  CROSS JOIN UNNEST(s.hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'              -- January-2017 only
    AND h.type = 'PAGE'
    AND LOWER(s.trafficSource.campaign) LIKE '%data share%'   -- campaign filter
),
home_hits AS (                           -- keep only the “/home…” pageviews
  SELECT *
  FROM flat
  WHERE this_path LIKE '/home%'
),
top_next AS (                            -- count which page comes next most often
  SELECT
    next_path,
    COUNT(*) AS after_home_cnt,
    ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS rn
  FROM home_hits
  WHERE next_path IS NOT NULL AND next_path != ''
  GROUP BY next_path
)
SELECT
  (SELECT next_path        FROM top_next WHERE rn = 1) AS most_common_next_page,
  (SELECT MAX(secs_on_home) FROM home_hits)            AS max_secs_on_home;