/*  December‑2020  –  Sessions per traffic channel  */
WITH session_events AS (

  /* ---------- 1 Dec → 31 Dec 2020 ---------- */
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230`
   WHERE event_name = 'session_start' UNION ALL
  SELECT user_pseudo_id, event_params, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
   WHERE event_name = 'session_start'
),

resolved_sessions AS (
  SELECT
      CONCAT(
        user_pseudo_id, '-',
        CAST( (SELECT ep.value.int_value
               FROM UNNEST(event_params) ep
               WHERE ep.key = 'ga_session_id'
               LIMIT 1) AS STRING)
      )                                                       AS session_key,

      COALESCE(
        traffic_source.source,
        (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
         WHERE ep.key = 'source'
         LIMIT 1)
      )                                                       AS source,

      COALESCE(
        traffic_source.medium,
        (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
         WHERE ep.key = 'medium'
         LIMIT 1)
      )                                                       AS medium
  FROM session_events
  WHERE (SELECT ep.value.int_value
         FROM UNNEST(event_params) ep
         WHERE ep.key = 'ga_session_id'
         LIMIT 1) IS NOT NULL
)

SELECT
  CASE
      WHEN source = '(direct)' AND medium IN ('(not set)', '(none)')                                                  THEN 'Direct'
      WHEN medium = 'referral'                                                                                        THEN 'Referral'
      WHEN REGEXP_CONTAINS(medium , r'email|e-mail|e_mail|e mail')  OR REGEXP_CONTAINS(source, r'email')               THEN 'Email'
      WHEN REGEXP_CONTAINS(medium , r'display|banner|expandable|interstitial|cpm')                                     THEN 'Display'
      WHEN REGEXP_CONTAINS(medium , r'ppc|cpc|paid')
           AND REGEXP_CONTAINS(source , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')                         THEN 'Paid Search'
      ELSE 'Unassigned'
  END                                       AS traffic_channel,
  COUNT(DISTINCT session_key)               AS total_sessions
FROM resolved_sessions
GROUP BY traffic_channel
ORDER BY total_sessions DESC;