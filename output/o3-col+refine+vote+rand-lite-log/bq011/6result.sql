-- Count pseudo-users with positive engagement in Jan-1–Jan-7
-- but none in Jan-6–Jan-7 (all dates 2021-01)
SELECT COUNT(*) AS distinct_pseudo_users
FROM (
  -- 7-day window (Jan-1 – Jan-7, 2021)
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021010*`,
       UNNEST(event_params) AS ep
  WHERE event_date BETWEEN '20210101' AND '20210107'
        AND ep.key = 'engagement_time_msec'
        AND ep.value.int_value > 0

  EXCEPT DISTINCT

  -- 2-day window (Jan-6 – Jan-7, 2021)
  SELECT DISTINCT user_pseudo_id
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_2021010*`,
       UNNEST(event_params) AS ep
  WHERE event_date BETWEEN '20210106' AND '20210107'
        AND ep.key = 'engagement_time_msec'
        AND ep.value.int_value > 0
);