-- Task: Could you please help me get the number of unique users who used our app during the second week starting from September 1st, 2018 (timezone in Shanghai)?
WITH analytics_data AS (
  SELECT user_pseudo_id, event_timestamp, event_name, 
    UNIX_MICROS(TIMESTAMP("2018-09-01 00:00:00", "+8:00")) AS start_day,
    3600*1000*1000*24*7 AS one_week_micros
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _table_suffix BETWEEN '20180901' AND '20180914'
)
SELECT COUNT(DISTINCT user_pseudo_id) AS week_1_users_count
FROM analytics_data
WHERE event_timestamp BETWEEN start_day + (1 * one_week_micros) AND start_day + (2 * one_week_micros)