/*--------------------------------------------------------------------
   Product-revenue analysis for 1H-2017 – use all export-days that 
   actually exist in the sample and contain product-revenue (6 days).
   1.  Union those tables
   2.  Flatten hits → product, keep rows that have productRevenue
   3.  Find the traffic-source with the highest cumulative revenue
   4.  For that source, return the maximum DAILY / WEEKLY / MONTHLY
       product-revenues (all expressed in millions)
--------------------------------------------------------------------*/
WITH sessions AS (        -- 6 export-days available in the sample
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170106"
    UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170203"
    UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170303"
    UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170401"
    UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170506"
    UNION ALL
    SELECT * FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170601"
),
/*---- flatten to product level and keep only rows with revenue ----*/
hits_prod AS (
    SELECT
        TO_DATE(s."date",'YYYYMMDD')               AS event_date,
        s."trafficSource":"source"::STRING         AS source,
        p.value:"productRevenue"::NUMBER / 1e6     AS product_revenue_million
    FROM sessions s,
         LATERAL FLATTEN(input => s."hits")   h,
         LATERAL FLATTEN(input => h.value:"product") p
    WHERE p.value:"productRevenue" IS NOT NULL
),
/*---- identify the single top-performing traffic-source ----*/
top_source AS (
    SELECT
        source,
        SUM(product_revenue_million) AS total_rev_million
    FROM hits_prod
    GROUP BY source
    ORDER BY total_rev_million DESC
    LIMIT 1
),
/*---- keep only rows that belong to that top source ----*/
filtered AS (
    SELECT hp.*
    FROM   hits_prod hp
    JOIN   top_source ts  ON hp.source = ts.source
),
/*---- aggregate to daily / weekly / monthly ----*/
daily   AS (SELECT event_date                            AS grp , SUM(product_revenue_million) AS rev FROM filtered GROUP BY grp),
weekly  AS (SELECT DATE_TRUNC('WEEK' ,event_date)        AS grp , SUM(product_revenue_million) AS rev FROM filtered GROUP BY grp),
monthly AS (SELECT DATE_TRUNC('MONTH',event_date)        AS grp , SUM(product_revenue_million) AS rev FROM filtered GROUP BY grp)

/*---- final output -------------------------------------------------*/
SELECT
       (SELECT source FROM top_source)                             AS top_traffic_source,
       (SELECT MAX(rev) FROM daily  )  AS max_daily_revenue_million,
       (SELECT MAX(rev) FROM weekly )  AS max_weekly_revenue_million,
       (SELECT MAX(rev) FROM monthly)  AS max_monthly_revenue_million;