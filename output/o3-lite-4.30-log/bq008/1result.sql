WITH sessions AS (
  SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170101`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170102`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170103`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170104`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170105`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170106`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170107`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170108`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170109`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170110`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170111`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170112`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170113`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170114`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170115`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170116`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170117`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170118`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170119`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170120`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170121`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170122`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170123`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170124`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170125`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170126`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170127`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170128`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170129`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170130`
  UNION ALL SELECT * FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170131`
),
page_hits AS (
  SELECT
    s.fullVisitorId,
    s.visitId,
    s.trafficSource.campaign AS campaign,
    h.hitNumber,
    h.time,
    h.page.pagePath AS page_path
  FROM sessions AS s
  CROSS JOIN UNNEST(s.hits) AS h
  WHERE h.type = 'PAGE'
),
home_sequences AS (
  SELECT
    fullVisitorId,
    visitId,
    page_path                                 AS home_path,
    LEAD(page_path) OVER w                    AS next_page,
    (LEAD(time) OVER w - time)/1000.0         AS secs_on_home
  FROM page_hits
  WHERE LOWER(campaign) LIKE '%data share%'
  WINDOW w AS (
    PARTITION BY fullVisitorId, visitId
    ORDER BY hitNumber
  )
)
SELECT
  next_page,
  ROUND(MAX(secs_on_home), 4) AS max_time_on_home_seconds
FROM home_sequences
WHERE home_path LIKE '/home%'     -- ensure current page is a home page
  AND next_page IS NOT NULL
GROUP BY next_page
ORDER BY COUNT(*) DESC
LIMIT 1;