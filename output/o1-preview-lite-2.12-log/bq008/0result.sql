SELECT
  next_page AS Page,
  MAX((next_time - time)/1000) AS Max_Time_On_Home_Page
FROM (
  SELECT
    s.fullVisitorId,
    s.visitId,
    h.hitNumber,
    h.time,
    h.page.pagePath AS current_page,
    LEAD(h.page.pagePath) OVER (
      PARTITION BY s.fullVisitorId, s.visitId
      ORDER BY h.hitNumber
    ) AS next_page,
    LEAD(h.time) OVER (
      PARTITION BY s.fullVisitorId, s.visitId
      ORDER BY h.hitNumber
    ) AS next_time
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s,
  UNNEST(s.hits) AS h
  WHERE
    _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
    AND LOWER(s.trafficSource.campaign) LIKE '%data share%'
    AND h.type = 'PAGE'
)
WHERE current_page LIKE '/home%'
  AND next_page IS NOT NULL
  AND current_page != next_page
GROUP BY Page
ORDER BY COUNT(*) DESC
LIMIT 1