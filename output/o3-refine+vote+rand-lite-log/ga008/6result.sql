-- Total daily page‑views in November‑2020 and the average page‑views per user,
-- restricted to users who made at least one purchase during November‑2020
WITH purchase_users AS (
    SELECT DISTINCT user_pseudo_id
    FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
          AND event_name = 'purchase'
),
daily_user_pageviews AS (
    SELECT
        event_date,                       -- YYYYMMDD string
        user_pseudo_id,
        COUNTIF(event_name = 'page_view') AS pageviews
    FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
    WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
          AND user_pseudo_id IN (SELECT user_pseudo_id FROM purchase_users)
    GROUP BY event_date, user_pseudo_id
)
SELECT
    PARSE_DATE('%Y%m%d', event_date)                AS event_date,
    SUM(pageviews)                                  AS total_pageviews,
    SAFE_DIVIDE(SUM(pageviews), COUNT(user_pseudo_id)) AS avg_pageviews_per_user
FROM daily_user_pageviews
GROUP BY event_date
ORDER BY event_date;