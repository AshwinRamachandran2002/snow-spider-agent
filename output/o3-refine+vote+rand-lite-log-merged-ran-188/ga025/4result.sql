/*  Percentage of Sept-2018 first-open users who uninstalled ≤ 7 days after first-open
    AND experienced at least one crash (app_exception) before that uninstall          */

WITH first_open AS (     -- each user’s very first “first_open” in Sept-2018
    SELECT
        user_pseudo_id,
        MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_open_date
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE _TABLE_SUFFIX LIKE '201809%'          -- only September-2018 partitions
      AND event_name = 'first_open'
    GROUP BY user_pseudo_id
),
uninstall AS (           -- each user’s earliest uninstall date
    SELECT
        user_pseudo_id,
        MIN(PARSE_DATE('%Y%m%d', event_date)) AS uninstall_date
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name = 'app_remove'
    GROUP BY user_pseudo_id
),
base AS (                -- keep users who uninstalled within 7 days of first-open
    SELECT
        fo.user_pseudo_id,
        fo.first_open_date,
        u.uninstall_date
    FROM first_open fo
    JOIN uninstall  u USING (user_pseudo_id)
    WHERE DATE_DIFF(u.uninstall_date, fo.first_open_date, DAY) <= 7
),
crash AS (               -- all crash events with their dates
    SELECT
        user_pseudo_id,
        PARSE_DATE('%Y%m%d', event_date) AS crash_date
    FROM `firebase-public-project.analytics_153293282.events_*`
    WHERE event_name = 'app_exception'
)

SELECT
    COUNT(DISTINCT CASE
                     WHEN c.user_pseudo_id IS NOT NULL THEN b.user_pseudo_id
                   END)                                       AS crashed_and_uninstalled_users ,
    COUNT(DISTINCT b.user_pseudo_id)                           AS uninstalled_users ,
    SAFE_DIVIDE(
        COUNT(DISTINCT CASE
                         WHEN c.user_pseudo_id IS NOT NULL THEN b.user_pseudo_id
                       END),
        COUNT(DISTINCT b.user_pseudo_id)
    )                                                          AS crash_percentage
FROM base b
LEFT JOIN crash c
  ON  b.user_pseudo_id = c.user_pseudo_id
  AND c.crash_date BETWEEN b.first_open_date AND b.uninstall_date ;