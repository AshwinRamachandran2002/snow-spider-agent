/*  Total number of sessions per traffic channel – December 2020 (values taken only from event_params)  */

WITH dec2020 AS (      -- explicit UNION of every December‑2020 daily table
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230` UNION ALL
  SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
),

/* extract parameters from session_start events */
session_start_params AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value     FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id')          AS ga_session_id,
    LOWER(
      (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'source')
    )                                                                                                   AS source,
    LOWER(
      (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'medium')
    )                                                                                                   AS medium
  FROM dec2020
  WHERE event_name = 'session_start'
  AND (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id') IS NOT NULL
),

/* one row per session */
sessions AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    ANY_VALUE(source) AS source,
    ANY_VALUE(medium) AS medium
  FROM session_start_params
  GROUP BY user_pseudo_id, ga_session_id
),

/* classify channel */
classified AS (
  SELECT
    CASE
      WHEN COALESCE(source, '') = '(direct)'
           AND COALESCE(medium, '') IN ('(not set)', '(none)', '')                           THEN 'Direct'
      WHEN medium = 'organic'                                                                THEN 'Organic Search'
      WHEN REGEXP_CONTAINS(medium, r'(.*cp.*|ppc|paid.*)')
           AND REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)') THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(medium, r'(.*cp.*|ppc|retargeting|paid.*)')
           AND REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)') THEN 'Paid Social'
      WHEN medium = 'referral'                                                               THEN 'Referral'
      ELSE 'Unassigned'
    END AS traffic_channel,
    CONCAT(user_pseudo_id, '_', CAST(ga_session_id AS STRING)) AS session_key
  FROM sessions
)

/* final counts */
SELECT
  traffic_channel,
  COUNT(DISTINCT session_key) AS total_sessions
FROM classified
GROUP BY traffic_channel
ORDER BY total_sessions DESC, traffic_channel;