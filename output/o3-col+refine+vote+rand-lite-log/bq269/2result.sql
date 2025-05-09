/*  Average pageviews per visitor for Purchase vs. Non-Purchase sessions
    (June-2017 vs. July-2017)                                            */

WITH sessions AS (                         -- all qualifying sessions
  SELECT
    SUBSTR(date,1,6) AS ym,                -- 201706 or 201707
    fullVisitorId,
    IF(totals.transactions IS NOT NULL
       AND totals.transactions > 0,
       'purchase','non_purchase') AS session_type,
    totals.pageviews AS pageviews
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20170601' AND '20170731'      -- Jun-01 to Jul-31 2017
    AND totals.pageviews IS NOT NULL                         -- keep only sessions with pageviews
),

per_visitor AS (                          -- sum pageviews per visitor-month & class
  SELECT
    ym,
    fullVisitorId,
    session_type,
    SUM(pageviews) AS pv
  FROM sessions
  GROUP BY ym, fullVisitorId, session_type
),

agg AS (                                  -- average across visitors
  SELECT
    ym,
    session_type,
    ROUND(AVG(pv),4) AS avg_pv
  FROM per_visitor
  GROUP BY ym, session_type
)

SELECT                                    -- side-by-side presentation
  session_type,
  MAX(IF(ym='201706', avg_pv, NULL)) AS june_avg_pageviews_per_visitor,
  MAX(IF(ym='201707', avg_pv, NULL)) AS july_avg_pageviews_per_visitor
FROM agg
GROUP BY session_type
ORDER BY session_type;