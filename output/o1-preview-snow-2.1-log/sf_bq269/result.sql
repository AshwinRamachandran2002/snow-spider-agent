WITH sessions AS (
    SELECT
        "fullVisitorId",
        TO_CHAR(DATE_TRUNC('month', TO_DATE(t."date", 'YYYYMMDD')), 'Mon-YYYY') AS "Month",
        t."totals":pageviews::NUMBER AS "pageviews",
        t."totals":transactions::NUMBER AS "transactions"
    FROM (
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170601"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170602"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170603"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170604"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170605"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170606"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170607"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170608"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170609"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170610"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170611"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170612"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170613"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170614"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170615"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170616"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170617"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170618"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170619"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170620"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170621"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170622"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170623"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170624"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170625"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170626"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170627"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170628"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170629"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170630"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170701"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170702"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170703"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170704"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170705"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170706"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170707"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170708"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170709"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170710"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170711"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170712"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170713"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170714"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170715"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170716"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170717"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170718"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170719"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170720"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170721"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170722"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170723"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170724"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170725"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170726"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170727"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170728"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170729"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170730"
        UNION ALL
        SELECT "fullVisitorId", "date", "totals" FROM GA360.GOOGLE_ANALYTICS_SAMPLE."GA_SESSIONS_20170731"
    ) t
    WHERE TO_DATE(t."date", 'YYYYMMDD') BETWEEN TO_DATE('20170601', 'YYYYMMDD') AND TO_DATE('20170731', 'YYYYMMDD')
),
visitor_pageviews AS (
    SELECT
        "fullVisitorId",
        "Month",
        SUM(CASE WHEN "transactions" > 0 THEN "pageviews" ELSE 0 END) AS "purchase_pageviews",
        SUM(CASE WHEN "transactions" = 0 OR "transactions" IS NULL THEN "pageviews" ELSE 0 END) AS "non_purchase_pageviews"
    FROM
        sessions
    GROUP BY
        "fullVisitorId", "Month"
),
final AS (
    SELECT
        "Month",
        ROUND(AVG(NULLIF("non_purchase_pageviews", 0)), 4) AS "Average_Pageviews_Non_Purchase",
        ROUND(AVG(NULLIF("purchase_pageviews", 0)), 4) AS "Average_Pageviews_Purchase"
    FROM
        visitor_pageviews
    GROUP BY
        "Month"
)
SELECT
    "Month",
    "Average_Pageviews_Non_Purchase",
    "Average_Pageviews_Purchase"
FROM
    final
ORDER BY
    "Month";