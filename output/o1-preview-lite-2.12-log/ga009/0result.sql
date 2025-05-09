SELECT
  ROUND(
    COUNT(DISTINCT CONCAT(CAST(ga_session_id AS STRING), '-', user_pseudo_id)) 
    / COUNT(DISTINCT user_pseudo_id), 
    4
  ) AS Average_Engaged_Sessions_Per_User
FROM (
  SELECT
    t.user_pseudo_id,
    (
      SELECT value.int_value
      FROM UNNEST(t.event_params)
      WHERE key = 'ga_session_id'
      LIMIT 1
    ) AS ga_session_id,
    (
      SELECT value.string_value
      FROM UNNEST(t.event_params)
      WHERE key = 'session_engaged'
      LIMIT 1
    ) AS session_engaged_value
  FROM `bigquery-public-data`.`ga4_obfuscated_sample_ecommerce`.`events_202012*` AS t
)
WHERE session_engaged_value = '1';