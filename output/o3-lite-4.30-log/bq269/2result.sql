/*  Average monthly page‑views per visitor (purchase vs. non‑purchase)
    for June‑July 2017 – Google‑Analytics sample data                               */

WITH all_sessions AS (
    /* ----------  explicit UNION of each day between 2017‑06‑01 and 2017‑07‑31  ---------- */
    SELECT fullVisitorId,
           totals.pageviews  AS pageviews,
           totals.transactions AS transactions,
           `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170601`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170602`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170603`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170604`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170605`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170606`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170607`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170608`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170609`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170610`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170611`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170612`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170613`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170614`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170615`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170616`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170617`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170618`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170619`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170620`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170621`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170622`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170623`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170624`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170625`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170626`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170627`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170628`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170629`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170630`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170701`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170702`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170703`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170704`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170705`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170706`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170707`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170708`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170709`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170710`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170711`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170712`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170713`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170714`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170715`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170716`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170717`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170718`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170719`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170720`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170721`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170722`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170723`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170724`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170725`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170726`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170727`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170728`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170729`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170730`
    UNION ALL SELECT fullVisitorId, totals.pageviews, totals.transactions, `date`
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170731`
),

/* ----------  classify sessions & keep those with page‑views  ---------- */
sessions_classified AS (
    SELECT
        FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', `date`)) AS month,
        fullVisitorId,
        pageviews,
        CASE WHEN transactions IS NOT NULL AND transactions >= 1
             THEN 'purchase' ELSE 'non_purchase' END        AS purchase_flag
    FROM all_sessions
    WHERE pageviews IS NOT NULL
),

/* ----------  sum page‑views per visitor‑month‑class  ---------- */
visitor_monthly AS (
    SELECT
        month,
        fullVisitorId,
        purchase_flag,
        SUM(pageviews) AS total_pageviews
    FROM sessions_classified
    GROUP BY month, fullVisitorId, purchase_flag
),

/* ----------  average page‑views per visitor within each month‑class  ---------- */
average_per_visitor AS (
    SELECT
        month,
        purchase_flag,
        AVG(total_pageviews) AS avg_pageviews
    FROM visitor_monthly
    GROUP BY month, purchase_flag
)

/* ----------  side‑by‑side result with four‑decimal precision  ---------- */
SELECT
    av.month,
    ROUND(MAX(IF(av.purchase_flag = 'purchase',     av.avg_pageviews, NULL)), 4) AS avg_pageviews_purchase,
    ROUND(MAX(IF(av.purchase_flag = 'non_purchase', av.avg_pageviews, NULL)), 4) AS avg_pageviews_non_purchase
FROM average_per_visitor AS av
GROUP BY av.month
ORDER BY av.month;