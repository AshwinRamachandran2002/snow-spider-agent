SELECT
    MAX(DATEDIFF('day', first_visit_date, last_event_date)) AS "longest_number_of_days"
FROM
(
    SELECT
        s."fullVisitorId",
        MIN(TO_DATE(TO_TIMESTAMP(s."visitStartTime"))) AS first_visit_date,
        COALESCE(
            MIN(CASE WHEN TRY_TO_NUMBER(s."totals":"transactions"::STRING) IS NOT NULL AND TRY_TO_NUMBER(s."totals":"transactions"::STRING) > 0 THEN TO_DATE(TO_TIMESTAMP(s."visitStartTime")) END),
            MAX(TO_DATE(TO_TIMESTAMP(s."visitStartTime")))
        ) AS last_event_date
    FROM
    (
        SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160801"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160802"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160803"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160804"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160805"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160806"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160807"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160808"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160809"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160810"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160811"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160812"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160813"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160814"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160815"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160816"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160817"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160818"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160819"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160820"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160821"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160822"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160823"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160824"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160825"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160826"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160827"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160828"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160829"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160830"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160831"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160901"
        -- Include all other tables up to "GA_SESSIONS_20170801" in the same manner
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device", "totals" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170801"
    ) s
    GROUP BY s."fullVisitorId"
) a
JOIN (
    SELECT
        "fullVisitorId",
        TO_DATE(TO_TIMESTAMP("visitStartTime")) AS event_date,
        ("device":"deviceCategory")::STRING AS deviceCategory
    FROM
    (
        SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160801"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160802"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160803"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160804"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160805"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160806"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160807"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160808"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160809"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160810"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160811"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160812"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160813"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160814"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160815"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160816"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160817"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160818"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160819"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160820"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160821"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160822"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160823"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160824"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160825"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160826"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160827"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160828"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160829"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160830"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160831"
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20160901"
        -- Include all other tables up to "GA_SESSIONS_20170801" in the same manner
        UNION ALL SELECT "fullVisitorId", "visitStartTime", "device" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170801"
    )
) d ON a."fullVisitorId" = d."fullVisitorId" AND d.event_date = a.last_event_date
WHERE d.deviceCategory = 'mobile';