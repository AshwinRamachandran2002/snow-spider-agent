-- 7‑day (weekly) retention for users whose very first session fell in the
-- Monday‑week that starts 2018‑07‑02.  Counts events only through 2018‑10‑02.

WITH first_session AS (      -- identify Week‑0 cohort
  SELECT
    user_pseudo_id,
    DATE_TRUNC(MIN(PARSE_DATE('%Y%m%d', event_date)), WEEK(MONDAY)) AS cohort_monday
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE event_name = 'session_start'
    AND _TABLE_SUFFIX BETWEEN '20180601' AND '20181002'
  GROUP BY user_pseudo_id
  HAVING cohort_monday = DATE '2018-07-02'          -- Week‑0 we care about
),

retention AS (               -- every event those cohort users fire
  SELECT DISTINCT
    fs.user_pseudo_id,
    -- weeks elapsed between the event’s Monday and the cohort’s Monday
    ( DATE_DIFF(
        DATE_TRUNC(PARSE_DATE('%Y%m%d', e.event_date), WEEK(MONDAY)),
        fs.cohort_monday,
        DAY) / 7 ) AS weeks_since_cohort
  FROM first_session fs
  JOIN `firebase-public-project.analytics_153293282.events_*` e
    USING (user_pseudo_id)
  WHERE e._TABLE_SUFFIX BETWEEN '20180702' AND '20181002'   -- events window
    -- keep only Week 0‑4 inclusive
    AND ( DATE_DIFF(
            DATE_TRUNC(PARSE_DATE('%Y%m%d', e.event_date), WEEK(MONDAY)),
            fs.cohort_monday,
            DAY) / 7 ) BETWEEN 0 AND 4
)

SELECT
  week_number,
  COUNT(DISTINCT user_pseudo_id) AS users
FROM (
  -- Week‑0: total new users
  SELECT 0 AS week_number, user_pseudo_id FROM first_session
  UNION ALL
  -- Weeks 1‑4: retained users (unique per week)
  SELECT weeks_since_cohort AS week_number, user_pseudo_id
  FROM retention
  WHERE weeks_since_cohort BETWEEN 1 AND 4
)
GROUP BY week_number
ORDER BY week_number;