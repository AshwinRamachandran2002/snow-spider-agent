WITH session_level AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX))        AS month,
    fullVisitorId,
    visitId,
    ANY_VALUE(totals.pageviews)                                      AS pageviews,
    ANY_VALUE(totals.transactions)                                   AS transactions,
    MAX(CASE WHEN p.productRevenue IS NOT NULL THEN 1 ELSE 0 END)   AS has_product_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS s
  LEFT JOIN UNNEST(s.hits)    AS h
  LEFT JOIN UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
  GROUP BY month, fullVisitorId, visitId
),
labeled_sessions AS (
  SELECT
    month,
    fullVisitorId,
    visitId,
    pageviews,
    CASE
      WHEN transactions >= 1 AND has_product_revenue = 1 THEN 'purchase'
      WHEN transactions IS NULL AND has_product_revenue = 0 THEN 'non_purchase'
    END AS session_group
  FROM session_level
  WHERE pageviews IS NOT NULL
),
visitor_month_group AS (
  SELECT
    month,
    session_group,
    fullVisitorId,
    SUM(pageviews) AS visitor_pageviews
  FROM labeled_sessions
  WHERE session_group IS NOT NULL
  GROUP BY month, session_group, fullVisitorId
)
SELECT
  month,
  session_group AS `group`,
  ROUND(AVG(visitor_pageviews), 4) AS avg_pageviews
FROM visitor_month_group
GROUP BY month, `group`
ORDER BY month, `group`;