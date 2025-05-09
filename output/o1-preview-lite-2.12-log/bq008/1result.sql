WITH next_pages AS (
  SELECT 
    h_next.page.pagePath AS Page,
    COUNT(*) AS num_transitions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s,
    UNNEST(s.hits) AS h
    JOIN UNNEST(s.hits) AS h_next
      ON h_next.hitNumber = h.hitNumber + 1
  WHERE 
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
    AND LOWER(s.trafficSource.campaign) LIKE '%data share%'
    AND h.page.pagePath LIKE '/home%'
  GROUP BY Page
  ORDER BY num_transitions DESC
  LIMIT 1
),
max_time_spent AS (
  SELECT
    MAX((h_next.time - h.time)/1000) AS Max_Time_On_Home_Page
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s,
    UNNEST(s.hits) AS h
    JOIN UNNEST(s.hits) AS h_next
      ON h_next.hitNumber = h.hitNumber + 1
  WHERE 
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
    AND LOWER(s.trafficSource.campaign) LIKE '%data share%'
    AND h.page.pagePath LIKE '/home%'
)

SELECT
  next_pages.Page,
  max_time_spent.Max_Time_On_Home_Page
FROM
  next_pages, max_time_spent