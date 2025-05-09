WITH
  next_pages AS (
    SELECT
      nextPage,
      COUNT(*) AS count
    FROM (
      SELECT
        LEAD(h.page.pagePath) OVER (PARTITION BY t.fullVisitorId, t.visitId ORDER BY h.hitNumber) AS nextPage
      FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*` AS t,
      UNNEST(t.hits) AS h
      WHERE t.trafficSource.campaign = 'Data Share Promo'
        AND h.type = 'PAGE'
        AND h.page.pagePath LIKE '/home%'
    )
    WHERE nextPage IS NOT NULL
    GROUP BY nextPage
    ORDER BY count DESC
    LIMIT 1
  ),
  max_duration AS (
    SELECT
      MAX(duration) AS max_duration_seconds
    FROM (
      SELECT
        LEAD(h.time) OVER (PARTITION BY t.fullVisitorId, t.visitId ORDER BY h.hitNumber) - h.time AS duration
      FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201701*` AS t,
      UNNEST(t.hits) AS h
      WHERE t.trafficSource.campaign = 'Data Share Promo'
        AND h.type = 'PAGE'
        AND h.page.pagePath LIKE '/home%'
    )
  )
SELECT
  next_pages.nextPage AS Next_page,
  max_duration.max_duration_seconds AS Maximum_duration_seconds
FROM
  next_pages,
  max_duration