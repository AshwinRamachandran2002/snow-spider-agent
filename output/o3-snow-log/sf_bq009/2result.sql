/* highest-revenue traffic-source for 2017 and the gap between its
   highest & lowest MONTHLY total-transaction-revenue (in millions)     */

WITH sessions AS (          /* union 2017 tables – choose only needed cols */
    SELECT "trafficSource", "totals", "date"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170101
    UNION ALL SELECT "trafficSource", "totals", "date"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170201
    UNION ALL SELECT "trafficSource", "totals", "date"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170301
    UNION ALL SELECT "trafficSource", "totals", "date"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170401
    UNION ALL SELECT "trafficSource", "totals", "date"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170501
    UNION ALL SELECT "trafficSource", "totals", "date"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170601
    UNION ALL SELECT "trafficSource", "totals", "date"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170701
    UNION ALL SELECT "trafficSource", "totals", "date"
      FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170801
), revenue_per_session AS (
    SELECT
        COALESCE("trafficSource":"source"::STRING, '(not set)')                    AS source,
        COALESCE("totals":"totalTransactionRevenue"::NUMBER, 0) / 1e6             AS revenue_million,
        TO_CHAR(TO_DATE("date", 'YYYYMMDD'), 'YYYY-MM')                           AS ym
    FROM sessions
    WHERE "date" LIKE '2017%'                     -- keep only 2017 rows
), top_source AS (                                -- source with max 2017 revenue
    SELECT source
    FROM   revenue_per_session
    GROUP  BY source
    ORDER  BY SUM(revenue_million) DESC NULLS LAST
    LIMIT  1
), monthly_rev AS (                               -- monthly revenue for that source
    SELECT  r.ym,
            SUM(r.revenue_million) AS month_revenue
    FROM    revenue_per_session r
    JOIN    top_source t
          ON r.source = t.source
    GROUP  BY r.ym
)
SELECT
       (SELECT source FROM top_source)  AS TRAFFIC_SOURCE,
       ROUND(MAX(month_revenue) - MIN(month_revenue), 2)  AS DIFF_MILLIONS
FROM   monthly_rev;