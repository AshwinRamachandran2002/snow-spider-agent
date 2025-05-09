SELECT
  t.next_page AS Next_page,
  MAX(t.duration_seconds) AS Maximum_duration_seconds
FROM (
  SELECT
    s.fullVisitorId,
    s.visitId,
    h.hitNumber,
    h.page.pagePath AS current_page,
    h.time AS current_time,
    LEAD(h.page.pagePath) OVER (PARTITION BY s.fullVisitorId, s.visitId ORDER BY h.hitNumber) AS next_page,
    LEAD(h.time) OVER (PARTITION BY s.fullVisitorId, s.visitId ORDER BY h.hitNumber) AS next_time,
    ((LEAD(h.time) OVER (PARTITION BY s.fullVisitorId, s.visitId ORDER BY h.hitNumber) - h.time)/1000) AS duration_seconds
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*` AS s,
  UNNEST(s.hits) AS h
  WHERE
    s.trafficSource.campaign = 'Data Share Promo'
    AND h.type = 'PAGE'
    AND h.page.pagePath LIKE '/home%'
) AS t
WHERE t.next_page IS NOT NULL
GROUP BY Next_page
ORDER BY COUNT(*) DESC
LIMIT 1;