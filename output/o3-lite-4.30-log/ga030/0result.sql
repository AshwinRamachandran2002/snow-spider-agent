WITH all_sessions AS (
  SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180612` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180613` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180614` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180615` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180616` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180617` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180618` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180619` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180620` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180621` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180622` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180623` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180624` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180625` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180626` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180627` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180628` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180629` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180630` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180701` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180702` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180703` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180704` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180705` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180706` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180707` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180708` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180709` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180710` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180711` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180712` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180713` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180714` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180715` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180716` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180717` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180718` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180719` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180720` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180721` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180722` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180723` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180724` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180725` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180726` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180727` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180728` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180729` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180730` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180731` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180801` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180802` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180803` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180804` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180805` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180806` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180807` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180808` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180809` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180810` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180811` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180812` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180813` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180814` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180815` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180816` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180817` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180818` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180819` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180820` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180821` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180822` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180823` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180824` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180825` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180826` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180827` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180828` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180829` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180830` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180831` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180901` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180902` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180903` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180904` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180905` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180906` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180907` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180908` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180909` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180910` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180911` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180912` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180913` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180914` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180915` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180916` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180917` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180918` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180919` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180920` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180921` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180922` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180923` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180924` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180925` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180926` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180927` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180928` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180929` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20180930` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20181001` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20181002` WHERE event_name = 'session_start'
  UNION ALL SELECT user_pseudo_id, event_date FROM `firebase-public-project.analytics_153293282.events_20181003` WHERE event_name = 'session_start'
),
first_session AS (
  SELECT
    user_pseudo_id,
    MIN(PARSE_DATE('%Y%m%d', event_date)) AS first_day
  FROM all_sessions
  GROUP BY user_pseudo_id
),
cohorts AS (
  SELECT
    user_pseudo_id,
    DATE_TRUNC(first_day, WEEK(MONDAY)) AS cohort_start
  FROM first_session
  WHERE first_day >= DATE '2018-07-02'
),
fourth_week_sessions AS (
  SELECT DISTINCT
    c.user_pseudo_id,
    c.cohort_start
  FROM cohorts c
  JOIN all_sessions s
    ON s.user_pseudo_id = c.user_pseudo_id
  WHERE PARSE_DATE('%Y%m%d', s.event_date)
        BETWEEN c.cohort_start + 21 AND c.cohort_start + 27
),
cohort_sizes AS (
  SELECT
    cohort_start,
    COUNT(*) AS total_users
  FROM cohorts
  GROUP BY cohort_start
),
retention AS (
  SELECT
    cs.cohort_start,
    SAFE_DIVIDE(COUNT(fws.user_pseudo_id), cs.total_users) AS week4_retention_rate
  FROM cohort_sizes cs
  LEFT JOIN fourth_week_sessions fws
    ON fws.cohort_start = cs.cohort_start
  GROUP BY cs.cohort_start, cs.total_users
)
SELECT
  FORMAT_DATE('%Y-%m-%d', cohort_start) AS cohort_start_date
FROM retention
ORDER BY week4_retention_rate DESC, cohort_start
LIMIT 1;