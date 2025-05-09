/*  Avg. pageviews per visitor (Purchase vs. Non-Purchase)
    April 01 – July 31  2017
*/
WITH sessions AS (
  -- one row per session
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', _TABLE_SUFFIX))      AS month ,
    fullVisitorId ,
    totals.pageviews                                               AS pageviews ,
    totals.transactions                                            AS transactions ,
    -- did the session include any positive productRevenue?
    EXISTS (
      SELECT 1
      FROM UNNEST(hits) h , UNNEST(h.product) p
      WHERE p.productRevenue IS NOT NULL
    )                                                             AS has_product_rev
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170401' AND '20170731'
),

visitors AS (
  -- aggregate to (month × visitor) level
  SELECT
    month ,
    fullVisitorId ,
    SUM(pageviews)                                   AS visitor_pageviews ,
    
    /* classify the *visitor* for the month
       ─────────────────────────────────────
       Purchase      : at least one session that is a purchase
       Non-Purchase  : all sessions are non-purchase
       Other         : mix of both or anything else                     */
    CASE
      WHEN SUM( CASE WHEN transactions >= 1 AND has_product_rev       THEN 1 END ) > 0
           THEN 'Purchase'
      WHEN SUM( CASE WHEN transactions IS NULL AND NOT has_product_rev THEN 1 END ) = COUNT(*)
           THEN 'Non-Purchase'
      ELSE 'Other'
    END                                             AS visitor_type
  FROM sessions
  GROUP BY month, fullVisitorId
)

SELECT
  month ,
  visitor_type ,
  AVG(visitor_pageviews)  AS avg_pageviews_per_visitor
FROM visitors
WHERE visitor_type IN ('Purchase','Non-Purchase')
GROUP BY month, visitor_type
ORDER BY month, visitor_type;