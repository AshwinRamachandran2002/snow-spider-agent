-- Task: Calculate the retention rates for weeks 1, 2, and 3 after initial use for the cohort of new customers who first opened our app ('first_open' event) between September 1st and September 7th, 2018 (Shanghai timezone). Retention rates are defined as the proportion of this initial cohort who were active in each subsequent week, based on events logged during September 2018. Display the retention rates in columns.

WITH analytics_data AS (
  SELECT user_pseudo_id, event_timestamp, event_name, 
    UNIX_MICROS(TIMESTAMP("2018-09-01 00:00:00", "+8:00")) AS start_day,
    3600*1000*1000*24*7 AS one_week_micros
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _table_suffix BETWEEN '20180901' AND '20180930'
)

SELECT
 week_1_cohort / week_0_cohort AS week_1_pct,
 week_2_cohort / week_0_cohort AS week_2_pct,
 week_3_cohort / week_0_cohort AS week_3_pct
FROM (
  WITH week_3_users AS (
    SELECT DISTINCT user_pseudo_id
    FROM analytics_data
    WHERE event_timestamp BETWEEN start_day+(3*one_week_micros) AND start_day+(4*one_week_micros)
  ),
  week_2_users AS (
    SELECT DISTINCT user_pseudo_id
    FROM analytics_data
    WHERE event_timestamp BETWEEN start_day+(2*one_week_micros) AND start_day+(3*one_week_micros)
  ),
  week_1_users AS (
    SELECT DISTINCT user_pseudo_id
    FROM analytics_data
    WHERE event_timestamp BETWEEN start_day+(1*one_week_micros) AND start_day+(2*one_week_micros)
  ), 
  week_0_users AS (
    SELECT DISTINCT user_pseudo_id
    FROM analytics_data
    WHERE event_name = 'first_open'
      AND event_timestamp BETWEEN start_day AND start_day+(1*one_week_micros)
  )
  SELECT 
    (SELECT count(*) 
     FROM week_0_users) AS week_0_cohort,
    (SELECT count(*) 
     FROM week_1_users 
     JOIN week_0_users USING (user_pseudo_id)) AS week_1_cohort,
    (SELECT count(*) 
     FROM week_2_users 
     JOIN week_0_users USING (user_pseudo_id)) AS week_2_cohort,
    (SELECT count(*) 
     FROM week_3_users 
     JOIN week_0_users USING (user_pseudo_id)) AS week_3_cohort
)