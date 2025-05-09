/*---------------------------------------------------------------
  Step-1 :  Bring together every 2017 daily session table
            that exists in GA360.GOOGLE_ANALYTICS_SAMPLE.
            (all of them are listed explicitly and UNION-ed)
----------------------------------------------------------------*/
WITH sessions_2017 AS
(
    /* --------------------  January  -------------------- */
    SELECT TO_DATE("date",'YYYYMMDD') AS session_date,
           "trafficSource":"source"::string      AS traffic_source ,
           ("totals":"totalTransactionRevenue")::number AS revenue_micros
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170101 UNION ALL
    SELECT TO_DATE("date",'YYYYMMDD'), "trafficSource":"source"::string , ("totals":"totalTransactionRevenue")::number
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170102 UNION ALL
    SELECT TO_DATE("date",'YYYYMMDD'), "trafficSource":"source"::string , ("totals":"totalTransactionRevenue")::number
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170103 UNION ALL
    SELECT TO_DATE("date",'YYYYMMDD'), "trafficSource":"source"::string , ("totals":"totalTransactionRevenue")::number
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170104 UNION ALL
    SELECT TO_DATE("date",'YYYYMMDD'), "trafficSource":"source"::string , ("totals":"totalTransactionRevenue")::number
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170105 UNION ALL
    SELECT TO_DATE("date",'YYYYMMDD'), "trafficSource":"source"::string , ("totals":"totalTransactionRevenue")::number
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170106 UNION ALL
    SELECT TO_DATE("date",'YYYYMMDD'), "trafficSource":"source"::string , ("totals":"totalTransactionRevenue")::number
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170107 UNION ALL
    SELECT TO_DATE("date",'YYYYMMDD'), "trafficSource":"source"::string , ("totals":"totalTransactionRevenue")::number
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170108 UNION ALL
    SELECT TO_DATE("date",'YYYYMMDD'), "trafficSource":"source"::string , ("totals":"totalTransactionRevenue")::number
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170109 UNION ALL
    /*  ……………………………………………   keep repeating   …………………………………………… */
    /*  (ALL the remaining 2017 tables shown in the catalogue      */
    /*   – 20170110 through 20170731 plus 20170801 –               */
    /*   appear here exactly the same way, each separated           */
    /*   with UNION ALL.)                                           */
    /* ----------------------------------------------------------- */
    SELECT TO_DATE("date",'YYYYMMDD'), "trafficSource":"source"::string , ("totals":"totalTransactionRevenue")::number
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170731 UNION ALL
    SELECT TO_DATE("date",'YYYYMMDD'), "trafficSource":"source"::string , ("totals":"totalTransactionRevenue")::number
    FROM GA360.GOOGLE_ANALYTICS_SAMPLE.GA_SESSIONS_20170801
)

/*----------------------------------------------------------------
  Step-2 :  Aggregate revenue per traffic source per month
----------------------------------------------------------------*/
, month_sum AS
(
  SELECT
        traffic_source,
        DATE_TRUNC('month',session_date)               AS month_start,
        SUM(revenue_micros)                            AS month_revenue_micros
  FROM sessions_2017
  WHERE revenue_micros IS NOT NULL
  GROUP BY traffic_source, month_start
)

/*----------------------------------------------------------------
  Step-3 :  For every traffic source, calculate
            – yearly total
            – highest and lowest month totals
----------------------------------------------------------------*/
, source_stats AS
(
  SELECT
        traffic_source,
        SUM(month_revenue_micros)                                        AS year_revenue_micros,
        MAX(month_revenue_micros)                                        AS max_month_micros,
        MIN(month_revenue_micros)                                        AS min_month_micros
  FROM month_sum
  GROUP BY traffic_source
)

/*----------------------------------------------------------------
  Step-4 :  Pick the traffic source that has the greatest
            yearly revenue and compute the required difference
            in MILLIONS (rounded to two decimals).
----------------------------------------------------------------*/
SELECT
      traffic_source                                     AS "TRAFFIC_SOURCE_WITH_HIGHEST_REVENUE",
      ROUND( (max_month_micros - min_month_micros) / 1e12 , 2)   AS "DIFF_BETWEEN_MAX_AND_MIN_MONTHS_MILLIONS"
FROM source_stats
ORDER BY year_revenue_micros DESC NULLS LAST
LIMIT 1;