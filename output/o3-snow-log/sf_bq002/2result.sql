/*  Top-performing traffic source and its peak daily, weekly & monthly
    product revenues (in millions) for the 1-Jan-2017 ➜ 30-Jun-2017 period  */

WITH union_sessions AS (          /* one exported table per month */
         /* Jan  */ SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170101"
         UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170118"
         /* Feb  */ UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170223"
         /* Mar  */ UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170309"
         /* Apr  */ UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170422"
         /* May  */ UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170518"
         /* Jun  */ UNION ALL SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170619"
),
product_hits AS (                 /* explode to the product level */
    SELECT
        s."date",
        s."trafficSource":"source"::STRING                    AS "source",
        prod.value:"productRevenue"::NUMBER / 1e6             AS "product_revenue_millions"
    FROM union_sessions AS s,
         LATERAL FLATTEN(input => s."hits")            AS h,
         LATERAL FLATTEN(input => h.value:"product")   AS prod
    WHERE prod.value:"productRevenue" IS NOT NULL
),
/* ------------------------------------------------------------------ */
source_totals AS (                /* total revenue per traffic source */
    SELECT  "source",
            SUM("product_revenue_millions") AS "total_revenue_millions"
    FROM    product_hits
    GROUP BY 1
    ORDER BY 2 DESC NULLS LAST
    LIMIT 1                                       -- keep the top-performer
),
filtered AS (                     /* keep only that top-performing source */
    SELECT ph.*
    FROM   product_hits ph
    JOIN   source_totals st
      ON   ph."source" = st."source"
),
daily AS (
    SELECT "date",
           SUM("product_revenue_millions") AS "daily_revenue_millions"
    FROM   filtered
    GROUP  BY 1
),
weekly AS (
    SELECT  LEFT("date",4)||'-'||TO_CHAR(TO_DATE("date",'YYYYMMDD'),'IW')
            AS "year_week",
            SUM("product_revenue_millions") AS "weekly_revenue_millions"
    FROM    filtered
    GROUP BY 1
),
monthly AS (
    SELECT LEFT("date",6)                    AS "year_month",
           SUM("product_revenue_millions")   AS "monthly_revenue_millions"
    FROM   filtered
    GROUP  BY 1
)
/* ------------------------------------------------------------------ */
SELECT
       st."source"                                   AS "top_source",
       st."total_revenue_millions",
       (SELECT MAX("daily_revenue_millions")   FROM daily)   AS "max_daily_revenue_millions",
       (SELECT MAX("weekly_revenue_millions")  FROM weekly)  AS "max_weekly_revenue_millions",
       (SELECT MAX("monthly_revenue_millions") FROM monthly) AS "max_monthly_revenue_millions"
FROM   source_totals st;