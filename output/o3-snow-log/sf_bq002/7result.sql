/*---------------------------------------------------------------------------
  First-half-of-2017 product-revenue (micro-units → millions)
  – pick one exported GA table per month (Jan-Jun 2017),
  – find the traffic-source with the highest total product-revenue,
  – return the maximum DAILY, WEEKLY and MONTHLY product-revenues
    (in millions) achieved by that source within the six sampled days.
---------------------------------------------------------------------------*/
WITH base AS (   -- keep only columns we need, one table per month
    SELECT "date","trafficSource","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170106" UNION ALL
    SELECT "date","trafficSource","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170223" UNION ALL
    SELECT "date","trafficSource","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170309" UNION ALL
    SELECT "date","trafficSource","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170422" UNION ALL
    SELECT "date","trafficSource","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170518" UNION ALL
    SELECT "date","trafficSource","hits" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170619"
),
revenues AS (    -- explode product arrays to individual revenue rows
    SELECT
        b."date",
        TO_CHAR(DATE_TRUNC('WEEK', TO_DATE(b."date",'YYYYMMDD')), 'YYYY-MM-DD')   AS week_key,
        SUBSTR(b."date",1,6)                                                      AS yyyymm,
        b."trafficSource":"source"::STRING                                        AS source,
        p.value:"productRevenue"::INTEGER                                         AS revenue_micro
    FROM base b,
         LATERAL FLATTEN(input => b."hits")        h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL
),
-- identify top traffic-source across the six sampled days
top_source AS (
    SELECT source
    FROM   revenues
    GROUP  BY source
    ORDER  BY SUM(revenue_micro) DESC NULLS LAST
    LIMIT  1
),
top_revenues AS (   -- keep only rows for that top source
    SELECT r.*
    FROM   revenues r
    JOIN   top_source t  USING (source)
),
/* ---------- DAILY, WEEKLY, MONTHLY aggregations ---------- */
daily_sums   AS (
    SELECT "date",        SUM(revenue_micro)/1e6 AS daily_rev_m
    FROM   top_revenues
    GROUP  BY "date"
),
weekly_sums  AS (
    SELECT week_key,     SUM(revenue_micro)/1e6 AS weekly_rev_m
    FROM   top_revenues
    GROUP  BY week_key
),
monthly_sums AS (
    SELECT yyyymm,       SUM(revenue_micro)/1e6 AS monthly_rev_m
    FROM   top_revenues
    GROUP  BY yyyymm
)
/* --------------------------- final answer --------------------------- */
SELECT
    (SELECT source           FROM top_source)         AS top_traffic_source,
    (SELECT MAX(daily_rev_m) FROM daily_sums)         AS max_daily_revenue_millions,
    (SELECT MAX(weekly_rev_m)FROM weekly_sums)        AS max_weekly_revenue_millions,
    (SELECT MAX(monthly_rev_m)FROM monthly_sums)      AS max_monthly_revenue_millions
;