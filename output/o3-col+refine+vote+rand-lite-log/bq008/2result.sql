-- Most common page visited after “/home” and the maximum time spent on “/home”
WITH hits_flat AS (
  SELECT
    fullVisitorId,
    visitId,
    h.hitNumber,
    h.time,
    h.page.pagePath AS pagePath
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*`,
       UNNEST(hits) AS h
  WHERE LOWER(trafficSource.campaign) LIKE '%data share%'         -- campaign filter
    AND h.page.pagePath IS NOT NULL                               -- keep only pageview hits
),
calc AS (
  SELECT
    pagePath,
    LEAD(pagePath) OVER (PARTITION BY fullVisitorId, visitId
                         ORDER BY hitNumber)                                             AS next_page,
    (LEAD(time) OVER (PARTITION BY fullVisitorId, visitId
                      ORDER BY hitNumber) - time) / 1000.0                               AS seconds_on_home
  FROM hits_flat
)
SELECT
  next_page                         AS most_common_next_page,
  MAX(seconds_on_home)              AS max_seconds_spent_on_home
FROM calc
WHERE pagePath LIKE '/home%'        -- hits on “/home…”
  AND next_page IS NOT NULL         -- must have a following hit
GROUP BY next_page
ORDER BY COUNT(*) DESC              -- most common next page
LIMIT 1;