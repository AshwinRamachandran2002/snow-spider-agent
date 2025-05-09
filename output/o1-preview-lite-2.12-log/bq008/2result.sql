SELECT
  nextPage AS Page,
  MAX(timeOnPage) AS Max_Time_On_Home_Page
FROM (
  SELECT
    t.fullVisitorId,
    t.visitId,
    h.hitNumber,
    h.page.pagePath AS currentPage,
    LEAD(h.page.pagePath) OVER (PARTITION BY t.fullVisitorId, t.visitId ORDER BY h.hitNumber) AS nextPage,
    h.time AS currentTime,
    LEAD(h.time) OVER (PARTITION BY t.fullVisitorId, t.visitId ORDER BY h.hitNumber) AS nextTime,
    (LEAD(h.time) OVER (PARTITION BY t.fullVisitorId, t.visitId ORDER BY h.hitNumber) - h.time) / 1000 AS timeOnPage
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*` AS t,
  UNNEST(t.hits) AS h
  WHERE t.trafficSource.campaign LIKE '%Data Share%'
)
WHERE currentPage LIKE '/home%' AND nextPage IS NOT NULL
GROUP BY Page
ORDER BY COUNT(*) DESC
LIMIT 1;