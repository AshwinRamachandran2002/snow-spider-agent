/* 7‑day retention (Week‑0 → Week‑4) for the cohort that had its first
   session_start during the week beginning Monday 2018‑07‑02,
   counting events only through 2018‑10‑02 and grouping by Monday weeks. */

WITH all_events AS (
  SELECT user_pseudo_id, event_name, event_date FROM (
      SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180612`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180613`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180614`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180615`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180616`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180617`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180618`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180619`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180620`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180621`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180622`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180623`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180624`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180625`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180626`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180627`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180628`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180629`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180630`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180701`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180702`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180703`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180704`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180705`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180706`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180707`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180708`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180709`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180710`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180711`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180712`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180713`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180714`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180715`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180716`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180717`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180718`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180719`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180720`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180721`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180722`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180723`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180724`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180725`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180726`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180727`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180728`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180729`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180730`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180731`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180801`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180802`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180803`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180804`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180805`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180806`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180807`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180808`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180809`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180810`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180811`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180812`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180813`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180814`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180815`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180816`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180817`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180818`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180819`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180820`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180821`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180822`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180823`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180824`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180825`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180826`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180827`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180828`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180829`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180830`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180831`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180901`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180902`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180903`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180904`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180905`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180906`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180907`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180908`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180909`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180910`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180911`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180912`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180913`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180914`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180915`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180916`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180917`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180918`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180919`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180920`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180921`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180922`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180923`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180924`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180925`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180926`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180927`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180928`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180929`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20180930`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20181001`
      UNION ALL SELECT user_pseudo_id, event_name, event_date FROM `firebase-public-project.analytics_153293282.events_20181002`
  )
),

-- Keep only session_start events
session_events AS (
  SELECT user_pseudo_id, event_date
  FROM all_events
  WHERE event_name = 'session_start'
),

-- Cohort: users whose FIRST session is between 2018‑07‑02 and 2018‑07‑08
cohort_users AS (
  SELECT user_pseudo_id
  FROM session_events
  GROUP BY user_pseudo_id
  HAVING MIN(event_date) BETWEEN '20180702' AND '20180708'
),

cohort_size AS (
  SELECT COUNT(*) AS cohort_size FROM cohort_users
),

-- All session_start touches made by cohort users (≤ 2018‑10‑02)
cohort_touches AS (
  SELECT
    s.user_pseudo_id,
    DATE_TRUNC(PARSE_DATE('%Y%m%d', s.event_date), WEEK(MONDAY)) AS week_start
  FROM session_events AS s
  JOIN cohort_users USING (user_pseudo_id)
),

-- Week index relative to the cohort week (Monday 2018‑07‑02)
week_flags AS (
  SELECT
    DATE_DIFF(week_start, DATE '2018-07-02', WEEK) AS week,
    user_pseudo_id
  FROM cohort_touches
  WHERE DATE_DIFF(week_start, DATE '2018-07-02', WEEK) BETWEEN 0 AND 4
)

-- Final result
SELECT
  week,
  cs.cohort_size,
  COUNT(DISTINCT CASE WHEN week > 0 THEN user_pseudo_id END) AS retained_users
FROM week_flags
CROSS JOIN cohort_size cs
GROUP BY week, cs.cohort_size
ORDER BY week;