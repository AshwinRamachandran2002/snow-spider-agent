/*  Weekly retention for users who triggered their very first
    `first_open` event during 1‒7 Sep 2018 (Asia/Shanghai time).

    Week-1 : 08‒14 Sep 2018
    Week-2 : 15‒21 Sep 2018
    Week-3 : 22‒28 Sep 2018
*/
WITH cohort AS (           -- users acquired in week-0
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180907'
    AND event_name = 'first_open'
),

week1 AS (                 -- users that returned in week-1
  SELECT DISTINCT e.user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*` AS e
  JOIN cohort USING (user_pseudo_id)
  WHERE e._TABLE_SUFFIX BETWEEN '20180908' AND '20180914'
),

week2 AS (                 -- users that returned in week-2
  SELECT DISTINCT e.user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*` AS e
  JOIN cohort USING (user_pseudo_id)
  WHERE e._TABLE_SUFFIX BETWEEN '20180915' AND '20180921'
),

week3 AS (                 -- users that returned in week-3
  SELECT DISTINCT e.user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*` AS e
  JOIN cohort USING (user_pseudo_id)
  WHERE e._TABLE_SUFFIX BETWEEN '20180922' AND '20180928'
)

SELECT
  (SELECT COUNT(*) FROM cohort)                                        AS cohort_users,
  (SELECT COUNT(*) FROM week1)                                         AS week1_users,
  ROUND(SAFE_DIVIDE((SELECT COUNT(*) FROM week1),
                    (SELECT COUNT(*) FROM cohort)), 4) AS week1_retention_rate,
  (SELECT COUNT(*) FROM week2)                                         AS week2_users,
  ROUND(SAFE_DIVIDE((SELECT COUNT(*) FROM week2),
                    (SELECT COUNT(*) FROM cohort)), 4) AS week2_retention_rate,
  (SELECT COUNT(*) FROM week3)                                         AS week3_users,
  ROUND(SAFE_DIVIDE((SELECT COUNT(*) FROM week3),
                    (SELECT COUNT(*) FROM cohort)), 4) AS week3_retention_rate;