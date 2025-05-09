WITH all_dec_events AS (
  SELECT event_params,
         user_pseudo_id,
         traffic_source.source  AS source,
         traffic_source.medium  AS medium,
         traffic_source.name    AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230`
  UNION ALL SELECT event_params, user_pseudo_id, traffic_source.source, traffic_source.medium, traffic_source.name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
),
sessions AS (
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id') AS ga_session_id,
    LOWER(COALESCE(source  , '')) AS source,
    LOWER(COALESCE(medium  , '')) AS medium,
    LOWER(COALESCE(campaign, '')) AS campaign
  FROM all_dec_events
),
channel_sessions AS (
  SELECT
    CASE
      WHEN source = '(direct)' AND medium IN ('(not set)','(none)','')                             THEN 'Direct'
      WHEN medium IN ('display','banner','expandable','interstitial','cpm')                        THEN 'Display'
      WHEN medium = 'affiliate'                                                                    THEN 'Affiliates'
      WHEN medium IN ('email','e-mail','e_mail','e mail') OR source IN ('email','e-mail','e_mail','e mail')
                                                                                                   THEN 'Email'
      WHEN medium = 'referral'                                                                     THEN 'Referral'
      WHEN (medium LIKE '%cpc%' OR medium LIKE '%ppc%' OR medium LIKE 'paid%')
           AND source IN ('google','bing','baidu','duckduckgo','yahoo','yandex','ecosia')          THEN 'Paid Search'
      WHEN (medium LIKE '%cpc%' OR medium LIKE '%ppc%' OR medium LIKE 'paid%')
           AND source IN ('amazon','alibaba','etsy','ebay','stripe','shopify','walmart','google shopping')
                                                                                                   THEN 'Paid Shopping'
      WHEN (medium LIKE '%cpc%' OR medium LIKE '%ppc%' OR medium LIKE '%retargeting%' OR medium LIKE 'paid%')
           AND source IN ('facebook','fb','instagram','linkedin','pinterest','tiktok','twitter','whatsapp','badoo')
                                                                                                   THEN 'Paid Social'
      WHEN medium = 'organic' OR source IN ('google','bing','baidu','duckduckgo','yahoo','yandex','ecosia')
                                                                                                   THEN 'Organic Search'
      ELSE 'Unassigned'
    END AS channel,
    COUNT(DISTINCT CONCAT(user_pseudo_id,'-',CAST(ga_session_id AS STRING))) AS total_sessions
  FROM sessions
  WHERE ga_session_id IS NOT NULL
  GROUP BY channel
),
ranked AS (
  SELECT
    channel,
    total_sessions,
    RANK() OVER (ORDER BY total_sessions DESC) AS rank
  FROM channel_sessions
)
SELECT
  rank,
  channel,
  total_sessions
FROM ranked
WHERE rank = 4;