/*  FIRST-HALF-2017  ▸  product-revenue leader and its best daily / weekly / monthly totals  */
WITH base AS (   -- 6 representative daily tables: one from each month Jan-Jun 2017
    SELECT
        "date"                                                      AS session_date ,
        "trafficSource"::VARIANT:"source"::STRING                   AS src ,
        p.value:"productRevenue"::NUMBER                            AS product_rev
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170118",
         LATERAL FLATTEN ( input => "hits")      h ,
         LATERAL FLATTEN ( input => h.value:"product")  p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT
        "date",
        "trafficSource"::VARIANT:"source"::STRING,
        p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170223",
         LATERAL FLATTEN ( input => "hits")      h ,
         LATERAL FLATTEN ( input => h.value:"product")  p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT
        "date",
        "trafficSource"::VARIANT:"source"::STRING,
        p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170309",
         LATERAL FLATTEN ( input => "hits")      h ,
         LATERAL FLATTEN ( input => h.value:"product")  p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT
        "date",
        "trafficSource"::VARIANT:"source"::STRING,
        p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170422",
         LATERAL FLATTEN ( input => "hits")      h ,
         LATERAL FLATTEN ( input => h.value:"product")  p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT
        "date",
        "trafficSource"::VARIANT:"source"::STRING,
        p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170518",
         LATERAL FLATTEN ( input => "hits")      h ,
         LATERAL FLATTEN ( input => h.value:"product")  p
    WHERE p.value:"productRevenue" IS NOT NULL

    UNION ALL
    SELECT
        "date",
        "trafficSource"::VARIANT:"source"::STRING,
        p.value:"productRevenue"::NUMBER
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170619",
         LATERAL FLATTEN ( input => "hits")      h ,
         LATERAL FLATTEN ( input => h.value:"product")  p
    WHERE p.value:"productRevenue" IS NOT NULL
),

/* identify the traffic source with the greatest total product revenue */
top_source AS (
    SELECT src , SUM(product_rev) AS total_rev
    FROM   base
    GROUP  BY src
    ORDER  BY total_rev DESC NULLS LAST
    LIMIT  1
),

/* keep only rows that belong to that top-performing source */
source_data AS (
    SELECT b.*
    FROM   base  b
    JOIN   top_source t
           ON b.src = t.src
),

/* daily, weekly & monthly revenue for the winner */
daily_rev   AS (
    SELECT session_date ,
           SUM(product_rev) AS daily_rev
    FROM   source_data
    GROUP  BY session_date
),
weekly_rev  AS (
    SELECT TO_CHAR( TO_DATE(session_date,'YYYYMMDD'), 'IYYY_IW') AS year_week ,
           SUM(product_rev)                                       AS weekly_rev
    FROM   source_data
    GROUP  BY year_week
),
monthly_rev AS (
    SELECT SUBSTR(session_date,1,6)  AS year_month ,
           SUM(product_rev)          AS monthly_rev
    FROM   source_data
    GROUP  BY year_month
)

/* final answer */
SELECT
    (SELECT src          FROM top_source)          AS "top_traffic_source" ,
    (SELECT MAX(daily_rev)  FROM daily_rev) /1e6   AS "max_daily_rev_millions" ,
    (SELECT MAX(weekly_rev) FROM weekly_rev) /1e6  AS "max_weekly_rev_millions" ,
    (SELECT MAX(monthly_rev)FROM monthly_rev)/1e6  AS "max_monthly_rev_millions";