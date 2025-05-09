WITH dec2020 AS (
  SELECT * FROM (
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230`
    UNION ALL SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
  )
),
event_level AS (
  SELECT
    user_pseudo_id,
    MAX(CASE WHEN ep.key = 'ga_session_id'   THEN ep.value.int_value END) AS ga_session_id,
    MAX(CASE WHEN ep.key = 'session_engaged' THEN ep.value.int_value END) AS session_engaged
  FROM dec2020
  CROSS JOIN UNNEST(event_params) AS ep
  GROUP BY user_pseudo_id, event_timestamp
),
session_level AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    MAX(session_engaged) AS session_engaged
  FROM event_level
  GROUP BY user_pseudo_id, ga_session_id
),
user_level AS (
  SELECT
    user_pseudo_id,
    COUNTIF(session_engaged = 1) AS engaged_sessions
  FROM session_level
  GROUP BY user_pseudo_id
)
SELECT
  ROUND(AVG(engaged_sessions), 4) AS average_engaged_sessions_per_user
FROM user_level;