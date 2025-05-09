SELECT
  ROUND(AVG(engaged_sessions_count), 4) AS Average_Engaged_Sessions_Per_User
FROM (
  SELECT
    user_pseudo_id,
    COUNT(DISTINCT ga_session_id) AS engaged_sessions_count
  FROM (
    SELECT
      user_pseudo_id,
      (SELECT ep.value.int_value
       FROM UNNEST(event_params) AS ep
       WHERE ep.key = 'ga_session_id' AND ep.value.int_value IS NOT NULL LIMIT 1) AS ga_session_id,
      (SELECT ep.value.int_value
       FROM UNNEST(event_params) AS ep
       WHERE ep.key = 'session_engaged' AND ep.value.int_value = 1 LIMIT 1) AS session_engaged
    FROM (
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230`
      UNION ALL
      SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
    )
  )
  WHERE session_engaged = 1 AND ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id
);