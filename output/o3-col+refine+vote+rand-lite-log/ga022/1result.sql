/*  Weekly retention for users whose very first `first_open`
    happened between 1-Sep-2018 and 7-Sep-2018 (Shanghai week-0).

    week1 : 08-Sep-2018 → 14-Sep-2018  
    week2 : 15-Sep-2018 → 21-Sep-2018  
    week3 : 22-Sep-2018 → 28-Sep-2018                                   */

WITH
-- 1. Cohort: all new users acquired in week-0
cohort AS (
  SELECT DISTINCT user_pseudo_id
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180901' AND '20180907'   -- 1-Sep … 7-Sep
    AND event_name = 'first_open'
),

-- 2. Later activity of those cohort users in weeks 1-3
activity AS (
  SELECT DISTINCT
         user_pseudo_id,
         CASE
           WHEN _TABLE_SUFFIX BETWEEN '20180908' AND '20180914' THEN 1
           WHEN _TABLE_SUFFIX BETWEEN '20180915' AND '20180921' THEN 2
           WHEN _TABLE_SUFFIX BETWEEN '20180922' AND '20180928' THEN 3
         END AS week_no
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180908' AND '20180928'   -- weeks 1-3
    AND user_pseudo_id IN (SELECT user_pseudo_id FROM cohort)
)

SELECT
  COUNT(*)                                                        AS cohort_size,
  ROUND(SAFE_DIVIDE(COUNTIF(week_no = 1), COUNT(*)), 4)  AS week1_retention,
  ROUND(SAFE_DIVIDE(COUNTIF(week_no = 2), COUNT(*)), 4)  AS week2_retention,
  ROUND(SAFE_DIVIDE(COUNTIF(week_no = 3), COUNT(*)), 4)  AS week3_retention
FROM cohort
LEFT JOIN activity USING (user_pseudo_id);