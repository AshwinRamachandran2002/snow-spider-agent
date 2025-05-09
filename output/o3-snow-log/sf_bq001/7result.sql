/*----------------------------------------------------------
For every visitor who placed at least one transaction
in February-2017:
  • first_visit_date = earliest session date in Feb
  • first_tx_date   = earliest Feb session whose totals.transactions > 0
  • days_to_tx      = days between the two
  • device_type     = device.deviceCategory used in that first-transaction session
----------------------------------------------------------*/
WITH feb_sessions AS (   -- all February-2017 sessions
    SELECT *
    FROM (
        SELECT "fullVisitorId",
               "date",
               "totals",
               "device",
               "visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170201"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170202"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170203"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170204"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170205"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170206"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170207"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170208"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170209"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170210"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170211"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170212"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170213"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170214"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170215"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170216"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170217"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170218"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170219"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170220"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170221"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170222"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170223"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170224"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170225"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170226"
        UNION ALL SELECT "fullVisitorId","date","totals","device","visitStartTime"
        FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170227"
    )
),
first_tx AS (          -- first transaction per visitor in Feb
    SELECT
        "fullVisitorId"                          AS visitor_id,
        TO_DATE("date",'YYYYMMDD')               AS tx_date,
        "device":"deviceCategory"::STRING        AS device_type,
        ROW_NUMBER() OVER (PARTITION BY "fullVisitorId"
                           ORDER BY TO_DATE("date",'YYYYMMDD'), "visitStartTime") AS rn
    FROM feb_sessions
    WHERE ("totals":"transactions"::NUMBER) > 0
),
first_tx_filtered AS (
    SELECT visitor_id, tx_date, device_type
    FROM first_tx
    WHERE rn = 1
),
first_visit AS (        -- first visit (any kind) in Feb
    SELECT
        "fullVisitorId"              AS visitor_id,
        MIN(TO_DATE("date",'YYYYMMDD')) AS first_visit_date
    FROM feb_sessions
    GROUP BY "fullVisitorId"
)
SELECT
    fv.visitor_id,
    DATEDIFF(day, fv.first_visit_date, ft.tx_date)      AS days_to_first_transaction,
    ft.device_type                                      AS first_tx_device
FROM first_tx_filtered ft
JOIN first_visit fv
  ON fv.visitor_id = ft.visitor_id
ORDER BY days_to_first_transaction, fv.visitor_id;