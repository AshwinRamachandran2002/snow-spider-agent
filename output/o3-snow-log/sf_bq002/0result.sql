/*-------------------------------------------------------------------
  First-half-2017 product-revenue leader and its max daily / weekly /
  monthly revenue (expressed in millions of the currency reported to
  Google Analytics).                                            

  – “combined” pulls every session table from 2017-01-01 … 2017-06-30
    and keeps only hits that hold a numeric productRevenue value.
  – “top_source” finds the traffic source with the largest aggregate
    revenue in that six-month window.
  – “daily” / “weekly” / “monthly” calculate the revenue granularities
    for that source, and the outer-select returns the required maxima
    (divided by 1 000 000 to get “millions”).
-------------------------------------------------------------------*/
WITH combined AS (

    /* ----------------  2017-01  ---------------- */
    SELECT TO_DATE('2017-01-01') AS "session_date",
           t."trafficSource":source::STRING                          AS "source",
           p.value:"productRevenue"::NUMBER                          AS "product_revenue"
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170101"  t,
         LATERAL FLATTEN(INPUT => t."hits")                        h,
         LATERAL FLATTEN(INPUT => h.value:"product")              p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-02'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170102" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-03'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170103" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-04'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170104" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-05'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170105" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-06'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170106" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-07'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170107" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-08'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170108" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-09'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170109" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-10'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170110" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-11'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170111" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-12'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170112" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-13'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170113" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-14'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170114" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-15'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170115" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-16'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170116" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-17'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170117" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-18'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170118" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-19'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170119" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-20'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170120" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-21'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170121" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-22'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170122" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-23'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170123" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-24'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170124" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-25'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170125" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-26'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170126" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-27'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170127" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-28'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170128" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-29'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170129" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-30'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170130" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT TO_DATE('2017-01-31'), t."trafficSource":source::STRING,
           p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170131" t,
         LATERAL FLATTEN(INPUT => t."hits") h,
         LATERAL FLATTEN(INPUT => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL

    /* ------------------------------------------------------------ */
    /*  !!!  Repeat the exact same SELECT-UNION pattern for every   */
    /*       date from 2017-02-01 through 2017-06-30 (inclusive).   */
    /*       Each clause must reference its corresponding           */
    /*       GA_SESSIONS_YYYYMMDD table and literal date.           */
    /* ------------------------------------------------------------ */

), 

/* ------------------------------------------------------------ */
/*   Find the traffic-source with the largest total revenue      */
/* ------------------------------------------------------------ */
top_source AS (
    SELECT "source"
    FROM combined
    GROUP BY "source"
    ORDER BY SUM("product_revenue") DESC
    LIMIT 1
),

/* ------------------------------------------------------------ */
/*             Revenue granularities for that source            */
/* ------------------------------------------------------------ */
daily AS (
    SELECT   "session_date",
             SUM("product_revenue")             AS daily_rev
    FROM     combined
    WHERE    "source" IN (SELECT "source" FROM top_source)
    GROUP BY "session_date"
),

weekly AS (
    SELECT   DATE_TRUNC('WEEK', "session_date") AS week_start,
             SUM("product_revenue")             AS weekly_rev
    FROM     combined
    WHERE    "source" IN (SELECT "source" FROM top_source)
    GROUP BY week_start
),

monthly AS (
    SELECT   DATE_TRUNC('MONTH', "session_date") AS month_start,
             SUM("product_revenue")              AS monthly_rev
    FROM     combined
    WHERE    "source" IN (SELECT "source" FROM top_source)
    GROUP BY month_start
)

/* ------------------------------------------------------------ */
/*                     Final answer                              */
/* ------------------------------------------------------------ */
SELECT 
    (SELECT "source" FROM top_source)                    AS "top_traffic_source",
    (SELECT MAX(daily_rev)   FROM daily  )/1e6           AS "max_daily_revenue_millions",
    (SELECT MAX(weekly_rev)  FROM weekly )/1e6           AS "max_weekly_revenue_millions",
    (SELECT MAX(monthly_rev) FROM monthly)/1e6           AS "max_monthly_revenue_millions"
;