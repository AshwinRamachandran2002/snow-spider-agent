WITH sessions AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX)) AS month,
    fullVisitorId,
    totals.pageviews                                           AS pageviews,
    CASE
      WHEN totals.transactions >= 1
           AND EXISTS (
             SELECT 1
             FROM   UNNEST(hits) h
             CROSS JOIN UNNEST(h.product) p
             WHERE  p.productRevenue IS NOT NULL
           ) THEN 'purchase'
      WHEN totals.transactions IS NULL
           AND NOT EXISTS (
             SELECT 1
             FROM   UNNEST(hits) h
             CROSS JOIN UNNEST(h.product) p
             WHERE  p.productRevenue IS NOT NULL
           ) THEN 'non-purchase'
    END AS grp
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),
visitor_month AS (
  SELECT
    month,
    grp,
    fullVisitorId,
    SUM(pageviews) AS pageviews_per_visitor
  FROM sessions
  WHERE grp IS NOT NULL
  GROUP BY month, grp, fullVisitorId
)
SELECT
  month,
  grp AS `group`,
  ROUND(AVG(pageviews_per_visitor), 4) AS avg_pageviews
FROM visitor_month
GROUP BY month, `group`
ORDER BY month, `group`;