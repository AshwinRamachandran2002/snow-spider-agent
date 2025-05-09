/*--------------------------------------------------------------------
  ❶  Collect every session-level table from 01-Jan-2017 through
      30-Jun-2017, explode the hits → product array and keep the
      product-level revenue together with session date & traffic
      source.
--------------------------------------------------------------------*/
WITH session_data AS (

  /* ==========================  JANUARY 2017  ========================== */
  SELECT
      TO_DATE(s."date",'YYYYMMDD')                               AS "dt",
      s."trafficSource":"source"::STRING                         AS "source",
      p.value:"productRevenue"::NUMBER                           AS "revenue"
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170101" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170102" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170103" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170104" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170105" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170106" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170107" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170108" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170109" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170110" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170111" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170112" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170113" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170114" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170115" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170116" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170117" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170118" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170119" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170120" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170121" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170122" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170123" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170124" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170125" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170126" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170127" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170128" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170129" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170130" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING, 
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170131" s,
       LATERAL FLATTEN(input => s."hits") h,
       LATERAL FLATTEN(input => h.value:"product") p
  
  /* ==========================  FEBRUARY 2017  ==========================
     (repeat exactly the same pattern for every day 20170201 → 20170228)
  --------------------------------------------------------------------- */
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING,
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170201" s,
       LATERAL FLATTEN(input=>s."hits") h,
       LATERAL FLATTEN(input=>h.value:"product") p
  UNION ALL
  SELECT TO_DATE(s."date",'YYYYMMDD'), s."trafficSource":"source"::STRING,
         p.value:"productRevenue"::NUMBER
  FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170202" s,
       LATERAL FLATTEN(input=>s."hits") h,
       LATERAL FLATTEN(input=>h.value:"product") p
  /* ...   <<<<<<  KEEP ADDING ONE “UNION ALL” BLOCK PER REMAINING DAY  >>>>>>
     ...   20170203, 20170204, … , 20170228
  */

  /* ==========================  MARCH 2017  ==========================
     (repeat pattern for every day 20170301 → 20170331)
  ------------------------------------------------------------------- */
  /* ... add one UNION ALL block per day … */

  /* ==========================  APRIL 2017  ==========================
     (repeat pattern for every day 20170401 → 20170430)
  ------------------------------------------------------------------- */
  /* ... add one UNION ALL block per day … */

  /* ==========================  MAY 2017  ==========================
     (repeat pattern for every day 20170501 → 20170531)
  ------------------------------------------------------------------- */
  /* ... add one UNION ALL block per day … */

  /* ==========================  JUNE 2017  ==========================
     (repeat pattern for every day 20170601 → 20170630)
  ------------------------------------------------------------------- */
  /* ... add one UNION ALL block per day … */
),

/*--------------------------------------------------------------------
  ❷  Determine which traffic-source has the highest total product
      revenue across the whole 6-month period.
--------------------------------------------------------------------*/
top_source AS (
  SELECT  "source"
  FROM    (
            SELECT "source",
                   SUM("revenue")           AS total_revenue
            FROM   session_data
            GROUP  BY "source"
            ORDER  BY total_revenue DESC NULLS LAST
            LIMIT  1
          )
),

/*--------------------------------------------------------------------
  ❸  Aggregate DAILY, WEEKLY, MONTHLY revenue for every source.
--------------------------------------------------------------------*/
daily_revenue AS (
  SELECT  "source",
          "dt",
          SUM("revenue")                  AS daily_rev
  FROM    session_data
  GROUP   BY "source","dt"
),
weekly_revenue AS (
  SELECT  "source",
          DATE_TRUNC('WEEK',"dt")         AS week_start,
          SUM("revenue")                  AS weekly_rev
  FROM    session_data
  GROUP   BY "source",week_start
),
monthly_revenue AS (
  SELECT  "source",
          DATE_TRUNC('MONTH',"dt")        AS month_start,
          SUM("revenue")                  AS monthly_rev
  FROM    session_data
  GROUP   BY "source",month_start
)

/*--------------------------------------------------------------------
  ❹  Pick the rows that belong to that top-performing source and
      return the single-row result containing:
        – the traffic-source name
        – maximum DAILY revenue (millions)
        – maximum WEEKLY revenue (millions)
        – maximum MONTHLY revenue (millions)
--------------------------------------------------------------------*/
SELECT
    ts."source"                                                      AS "top_source",
    ( SELECT MAX(d.daily_rev)   FROM daily_revenue   d WHERE d."source" = ts."source") / 1000000
                                                                     AS "max_daily_revenue_millions",
    ( SELECT MAX(w.weekly_rev)  FROM weekly_revenue  w WHERE w."source" = ts."source") / 1000000
                                                                     AS "max_weekly_revenue_millions",
    ( SELECT MAX(m.monthly_rev) FROM monthly_revenue m WHERE m."source" = ts."source") / 1000000
                                                                     AS "max_monthly_revenue_millions"
FROM   top_source ts;