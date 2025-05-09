WITH sessions AS (
  SELECT
    t.user_pseudo_id,
    ga_session_id.value.int_value AS session_id,
    LOWER(COALESCE(source.value.string_value, '(direct)')) AS source,
    LOWER(COALESCE(medium.value.string_value, '(none)')) AS medium,
    LOWER(COALESCE(campaign.value.string_value, '')) AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` AS t
  LEFT JOIN UNNEST(t.event_params) AS ga_session_id ON ga_session_id.key = 'ga_session_id'
  LEFT JOIN UNNEST(t.event_params) AS source ON source.key = 'source'
  LEFT JOIN UNNEST(t.event_params) AS medium ON medium.key = 'medium'
  LEFT JOIN UNNEST(t.event_params) AS campaign ON campaign.key = 'campaign'
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND t.event_name = 'session_start'
    AND ga_session_id.value.int_value IS NOT NULL
),
mapped_sessions AS (
  SELECT
    *,
    CASE
      WHEN source = '(direct)' AND medium IN ('(not set)', '(none)') THEN 'Direct'
      WHEN campaign LIKE '%cross-network%' THEN 'Cross-network'
      WHEN (source IN ('alibaba', 'amazon', 'google shopping', 'shopify', 'etsy', 'ebay', 'stripe', 'walmart') OR campaign LIKE '%shop%' OR campaign LIKE '%shopping%')
           AND medium IN ('cp', 'ppc', 'retargeting', 'paid') THEN 'Paid Shopping'
      WHEN source IN ('baidu', 'bing', 'duckduckgo', 'ecosia', 'google', 'yahoo', 'yandex')
           AND medium IN ('cp', 'ppc', 'paid') THEN 'Paid Search'
      WHEN source IN ('badoo', 'facebook', 'fb', 'instagram', 'linkedin', 'pinterest', 'tiktok', 'twitter', 'whatsapp')
           AND medium IN ('cp', 'ppc', 'retargeting', 'paid') THEN 'Paid Social'
      WHEN source IN ('dailymotion', 'disneyplus', 'netflix', 'youtube', 'vimeo', 'twitch')
           AND medium IN ('cp', 'ppc', 'retargeting', 'paid') THEN 'Paid Video'
      WHEN medium IN ('display', 'banner', 'expandable', 'interstitial', 'cpm') THEN 'Display'
      WHEN medium = 'affiliate' THEN 'Affiliates'
      WHEN medium = 'audio' THEN 'Audio'
      WHEN source IN ('email', 'e-mail', 'e_mail', 'e mail') OR medium IN ('email', 'e-mail', 'e_mail', 'e mail') THEN 'Email'
      WHEN RIGHT(medium, 4) = 'push' OR medium LIKE '%mobile%' OR medium LIKE '%notification%' THEN 'Mobile Push Notifications'
      WHEN source = 'sms' OR medium = 'sms' THEN 'SMS'
      WHEN (source IN ('alibaba', 'amazon', 'google shopping', 'shopify', 'etsy', 'ebay', 'stripe', 'walmart') OR campaign LIKE '%shop%' OR campaign LIKE '%shopping%') THEN 'Organic Shopping'
      WHEN source IN ('baidu', 'bing', 'duckduckgo', 'ecosia', 'google', 'yahoo', 'yandex') OR medium = 'organic' THEN 'Organic Search'
      WHEN source IN ('badoo', 'facebook', 'fb', 'instagram', 'linkedin', 'pinterest', 'tiktok', 'twitter', 'whatsapp') OR medium IN ('social', 'social-network', 'social-media', 'sm', 'social network', 'social media') THEN 'Organic Social'
      WHEN source IN ('dailymotion', 'disneyplus', 'netflix', 'youtube', 'vimeo', 'twitch') OR medium LIKE '%video%' THEN 'Organic Video'
      WHEN medium = 'referral' THEN 'Referral'
      ELSE 'Unassigned'
    END AS Channel
  FROM sessions
)
SELECT
  Channel,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', CAST(session_id AS STRING))) AS Sessions
FROM mapped_sessions
GROUP BY Channel
ORDER BY Sessions DESC;