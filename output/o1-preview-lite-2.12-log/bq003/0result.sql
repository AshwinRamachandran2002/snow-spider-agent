SELECT
  Month,
  `Group`,
  AVG(pageviews) AS Average_Pageviews_Per_Visitor
FROM (
  SELECT
    Month,
    fullVisitorId,
    SUM(pageviews) AS pageviews,
    `Group`
  FROM (
    SELECT
      FORMAT_DATE('%B-%Y', PARSE_DATE('%Y%m%d', date)) AS Month,
      fullVisitorId,
      totals.pageviews AS pageviews,
      CASE
        WHEN totals.transactions >= 1 AND has_product_revenue THEN 'Purchase'
        WHEN totals.transactions IS NULL AND NOT has_product_revenue THEN 'Non-Purchase'
        ELSE 'Other'
      END AS `Group`
    FROM (
      SELECT
        date,
        fullVisitorId,
        totals,
        EXISTS(
          SELECT 1
          FROM UNNEST(hits) AS h
          LEFT JOIN UNNEST(h.product) AS p ON TRUE
          WHERE p.productRevenue IS NOT NULL
        ) AS has_product_revenue
      FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
      WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
    )
  )
  WHERE `Group` IN ('Purchase', 'Non-Purchase')
  GROUP BY Month, fullVisitorId, `Group`
)
GROUP BY Month, `Group`
ORDER BY Month, `Group`;