WITH sessions_data AS (
  SELECT
    event_name,
    user_pseudo_id,
    event_timestamp,
    CASE
      WHEN traffic_source.source = '(direct)' AND traffic_source.medium IN ('(not set)', '(none)') THEN 'Direct'
      WHEN LOWER(traffic_source.name) LIKE '%cross-network%' THEN 'Cross-network'
      WHEN (
           LOWER(traffic_source.source) IN ('alibaba','amazon','google shopping','shopify','etsy','ebay','stripe','walmart')
           OR REGEXP_CONTAINS(LOWER(traffic_source.name), r'^(.*(([^a-df-z]|^)shop|shopping).*)$')
          )
          AND REGEXP_CONTAINS(LOWER(traffic_source.medium), r'(.*cp.*|ppc|retargeting|paid.*)') THEN 'Paid Shopping'
      WHEN LOWER(traffic_source.source) IN ('baidu','bing','duckduckgo','ecosia','google','yahoo','yandex') AND REGEXP_CONTAINS(LOWER(traffic_source.medium), r'(.*cp.*|ppc|paid.*)') THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(LOWER(traffic_source.source), r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)') AND REGEXP_CONTAINS(LOWER(traffic_source.medium), r'(.*cp.*|ppc|retargeting|paid.*)') THEN 'Paid Social'
      WHEN LOWER(traffic_source.source) IN ('dailymotion','disneyplus','netflix','youtube','vimeo','twitch') AND REGEXP_CONTAINS(LOWER(traffic_source.medium), r'(.*cp.*|ppc|retargeting|paid.*)') THEN 'Paid Video'
      WHEN LOWER(traffic_source.medium) IN ('display', 'banner', 'expandable', 'interstitial', 'cpm') THEN 'Display'
      WHEN (
           LOWER(traffic_source.source) IN ('alibaba','amazon','google shopping','shopify','etsy','ebay','stripe','walmart')
           OR REGEXP_CONTAINS(LOWER(traffic_source.name), r'^(.*(([^a-df-z]|^)shop|shopping).*)$')
          ) THEN 'Organic Shopping'
      WHEN REGEXP_CONTAINS(LOWER(traffic_source.source), r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
          OR LOWER(traffic_source.medium) IN ('social','social-network','social-media','sm','social network','social media') THEN 'Organic Social'
      WHEN LOWER(traffic_source.source) IN ('dailymotion','disneyplus','netflix','youtube','vimeo','twitch') OR REGEXP_CONTAINS(LOWER(traffic_source.medium), r'(.*video.*)') THEN 'Organic Video'
      WHEN LOWER(traffic_source.source) IN ('baidu','bing','duckduckgo','ecosia','google','yahoo','yandex') OR LOWER(traffic_source.medium) = 'organic' THEN 'Organic Search'
      WHEN LOWER(traffic_source.medium) = 'referral' THEN 'Referral'
      WHEN LOWER(traffic_source.source) IN ('email','e-mail','e_mail','e mail') OR LOWER(traffic_source.medium) IN ('email','e-mail','e_mail','e mail') THEN 'Email'
      WHEN LOWER(traffic_source.medium) = 'affiliate' THEN 'Affiliates'
      WHEN LOWER(traffic_source.medium) = 'audio' THEN 'Audio'
      WHEN LOWER(traffic_source.source) = 'sms' OR LOWER(traffic_source.medium) = 'sms' THEN 'SMS'
      WHEN LOWER(traffic_source.medium) LIKE '%push' OR LOWER(traffic_source.medium) LIKE '%mobile%' OR LOWER(traffic_source.medium) LIKE '%notification%' THEN 'Mobile Push Notifications'
      ELSE 'Unassigned'
    END AS channel
  FROM (
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230`
    UNION ALL
    SELECT event_name, user_pseudo_id, event_timestamp, traffic_source
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
  )
  WHERE event_name = 'session_start'
), sessions_per_channel AS (
  SELECT
    channel,
    COUNT(DISTINCT CONCAT(user_pseudo_id, CAST(event_timestamp AS STRING))) AS sessions
  FROM sessions_data
  GROUP BY channel
)
SELECT
  sessions AS `Fourth-highest-sessions`,
  channel AS `Channel`
FROM (
  SELECT
    channel,
    sessions,
    ROW_NUMBER() OVER (ORDER BY sessions DESC) AS rn
  FROM sessions_per_channel
)
WHERE rn = 4