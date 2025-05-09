/*  Percentage of August-September-2018 installers who either
    1) never un-installed, or
    2) un-installed more than 7 days after install                         */

SELECT
  ROUND(
        100 * COUNT(DISTINCT CASE
                 WHEN ar.first_uninstall_date IS NULL
                      OR DATE_DIFF(PARSE_DATE('%Y%m%d', ar.first_uninstall_date),
                                   PARSE_DATE('%Y%m%d', fo.event_date), DAY) > 7
                 THEN fo.user_pseudo_id
             END)
/        COUNT(DISTINCT fo.user_pseudo_id)
       ,4)                                                   AS pct_survived_7d
FROM   `firebase-public-project.analytics_153293282.events_*`  fo
LEFT JOIN (
        SELECT  user_pseudo_id,
                MIN(event_date) AS first_uninstall_date
        FROM    `firebase-public-project.analytics_153293282.events_*`
        WHERE   _TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
          AND   event_name = 'app_remove'
        GROUP BY user_pseudo_id
) ar
ON     fo.user_pseudo_id = ar.user_pseudo_id
WHERE  fo._TABLE_SUFFIX BETWEEN '20180801' AND '20180930'
  AND  fo.event_name     = 'first_open';