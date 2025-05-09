WITH all_sessions AS (
    SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170601"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170602"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170603"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170604"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170605"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170606"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170607"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170608"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170609"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170610"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170611"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170612"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170613"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170614"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170615"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170616"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170617"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170618"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170619"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170620"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170621"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170622"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170623"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170624"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170625"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170626"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170627"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170628"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170629"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170630"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170701"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170702"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170703"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170704"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170705"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170706"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170707"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170708"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170709"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170710"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170711"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170712"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170713"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170714"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170715"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170716"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170717"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170718"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170719"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170720"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170721"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170722"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170723"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170724"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170725"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170726"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170727"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170728"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170729"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170730"
    UNION ALL SELECT "fullVisitorId", "visitId", "date", "totals", "hits" FROM "GA360"."GOOGLE_ANALYTICS_SAMPLE"."GA_SESSIONS_20170731"
),
session_data AS (
    SELECT
        t."fullVisitorId",
        t."visitId",
        t."totals":"pageviews"::INT AS pageviews,
        t."hits",
        TO_CHAR(TO_DATE(t."date", 'YYYYMMDD'), 'Mon-YYYY') AS "Month"
    FROM all_sessions t
),
sessions_with_purchase_flag AS (
    SELECT
        s."fullVisitorId",
        s."visitId",
        s.pageviews,
        s."Month",
        MAX(CASE WHEN h.value:"eCommerceAction":"action_type"::STRING = '6' THEN 1 ELSE 0 END) AS is_purchase_session
    FROM
        session_data s,
        LATERAL FLATTEN(input => s."hits") h
    GROUP BY
        s."fullVisitorId", s."visitId", s.pageviews, s."Month"
),
visitor_pageviews AS (
    SELECT
        s."fullVisitorId",
        s."Month",
        SUM(CASE WHEN s.is_purchase_session = 1 THEN s.pageviews ELSE 0 END) AS purchase_pageviews,
        SUM(CASE WHEN s.is_purchase_session = 0 THEN s.pageviews ELSE 0 END) AS non_purchase_pageviews
    FROM
        sessions_with_purchase_flag s
    GROUP BY
        s."fullVisitorId", s."Month"
)
SELECT
    "Month",
    ROUND(AVG(CASE WHEN non_purchase_pageviews > 0 THEN non_purchase_pageviews END), 4) AS "Average_Pageviews_Non_Purchase",
    ROUND(AVG(CASE WHEN purchase_pageviews > 0 THEN purchase_pageviews END), 4) AS "Average_Pageviews_Purchase"
FROM
    visitor_pageviews
GROUP BY
    "Month"
ORDER BY
    TO_DATE("Month", 'Mon-YYYY');