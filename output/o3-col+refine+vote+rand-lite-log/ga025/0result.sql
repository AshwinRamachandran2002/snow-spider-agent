/*  Percentage of Sept-2018 first-open users who un-installed ≤7 days later
    AND experienced at least one crash (app_exception) before the uninstall   */

WITH first_open_sept AS (          -- very first “first_open” in Sept-2018
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_open_date
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE event_name = 'first_open'
  GROUP BY user_pseudo_id
),

first_uninstall AS (               -- first “app_remove” in Sept/early-Oct
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS uninstall_date
  FROM (
    SELECT user_pseudo_id, event_date
    FROM `firebase-public-project.analytics_153293282.events_201809*`
    WHERE event_name = 'app_remove'
    UNION ALL
    SELECT user_pseudo_id, event_date
    FROM `firebase-public-project.analytics_153293282.events_2018100*`
    WHERE event_name = 'app_remove'
  )
  GROUP BY user_pseudo_id
),

cohort AS (                        -- keep only uninstalls that happened ≤7 days
  SELECT
    fo.user_pseudo_id,
    fo.first_open_date,
    un.uninstall_date
  FROM first_open_sept fo
  JOIN first_uninstall un
    ON fo.user_pseudo_id = un.user_pseudo_id
  WHERE DATE_DIFF(un.uninstall_date, fo.first_open_date, DAY) BETWEEN 0 AND 7
),

crashes AS (                       -- every crash with its calendar date
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS crash_date
  FROM `firebase-public-project.analytics_153293282.events_201809*`
  WHERE event_name = 'app_exception'
  UNION ALL
  SELECT
    user_pseudo_id,
    PARSE_DATE('%Y%m%d', event_date) AS crash_date
  FROM `firebase-public-project.analytics_153293282.events_2018100*`
  WHERE event_name = 'app_exception'
),

cohort_with_crash AS (             -- cohort members who crashed before uninstall
  SELECT DISTINCT c.user_pseudo_id
  FROM cohort c
  JOIN crashes cr
    ON  c.user_pseudo_id = cr.user_pseudo_id
   AND cr.crash_date BETWEEN c.first_open_date AND c.uninstall_date
)

SELECT
  COUNT(DISTINCT c.user_pseudo_id)               AS users_uninstalled_le7d,
  COUNT(DISTINCT cc.user_pseudo_id)              AS users_uninstalled_le7d_and_crashed,
  ROUND(
    SAFE_DIVIDE(COUNT(DISTINCT cc.user_pseudo_id),
                COUNT(DISTINCT c.user_pseudo_id)) * 100, 4
  )                                              AS pct_with_crash
FROM cohort c
LEFT JOIN cohort_with_crash cc
  ON c.user_pseudo_id = cc.user_pseudo_id;