WITH sessions AS (
  SELECT
    t.user_pseudo_id,
    IFNULL(
      (SELECT ep.value.int_value FROM UNNEST(t.event_params) ep WHERE ep.key = 'ga_session_id'),
      t.event_timestamp
    ) AS ga_session_id,
    COALESCE(LOWER(t.traffic_source.medium), '') AS traffic_medium,
    COALESCE(LOWER(t.traffic_source.source), '') AS traffic_source,
    COALESCE(LOWER(t.traffic_source.name), '') AS traffic_name
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS t
  WHERE
    t.event_name = 'session_start'
)

SELECT
  Channel,
  COUNT(*) AS Sessions
FROM (
  SELECT DISTINCT
    user_pseudo_id,
    ga_session_id,
    CASE
      WHEN traffic_source = '(direct)' AND traffic_medium IN ('(not set)', '(none)', '') THEN 'Direct'
      WHEN traffic_name LIKE '%cross-network%' THEN 'Cross-network'
      WHEN (
        traffic_source IN ('alibaba', 'amazon', 'google shopping', 'shopify', 'etsy', 'ebay', 'stripe', 'walmart') OR
        REGEXP_CONTAINS(traffic_name, r'(^|[^a-df-z])(shop|shopping)')
      ) AND REGEXP_CONTAINS(traffic_medium, r'(cp|ppc|retargeting|paid)') THEN 'Paid Shopping'
      WHEN traffic_source IN ('baidu', 'bing', 'duckduckgo', 'ecosia', 'google', 'yahoo', 'yandex') AND REGEXP_CONTAINS(traffic_medium, r'(cp|ppc|paid)') THEN 'Paid Search'
      WHEN traffic_source IN ('badoo', 'facebook', 'fb', 'instagram', 'linkedin', 'pinterest', 'tiktok', 'twitter', 'whatsapp') AND REGEXP_CONTAINS(traffic_medium, r'(cp|ppc|retargeting|paid)') THEN 'Paid Social'
      WHEN traffic_source IN ('dailymotion', 'disneyplus', 'netflix', 'youtube', 'vimeo', 'twitch') AND REGEXP_CONTAINS(traffic_medium, r'(cp|ppc|retargeting|paid)') THEN 'Paid Video'
      WHEN traffic_medium IN ('display', 'banner', 'expandable', 'interstitial', 'cpm') THEN 'Display'
      WHEN (
        traffic_source IN ('alibaba', 'amazon', 'google shopping', 'shopify', 'etsy', 'ebay', 'stripe', 'walmart') OR
        REGEXP_CONTAINS(traffic_name, r'(^|[^a-df-z])(shop|shopping)')
      ) THEN 'Organic Shopping'
      WHEN traffic_source IN ('badoo', 'facebook', 'fb', 'instagram', 'linkedin', 'pinterest', 'tiktok', 'twitter', 'whatsapp') OR traffic_medium IN ('social', 'social-network', 'social-media', 'sm', 'social network', 'social media') THEN 'Organic Social'
      WHEN traffic_source IN ('dailymotion', 'disneyplus', 'netflix', 'youtube', 'vimeo', 'twitch') OR REGEXP_CONTAINS(traffic_medium, 'video') THEN 'Organic Video'
      WHEN traffic_source IN ('baidu', 'bing', 'duckduckgo', 'ecosia', 'google', 'yahoo', 'yandex') OR traffic_medium = 'organic' THEN 'Organic Search'
      WHEN traffic_medium = 'referral' THEN 'Referral'
      WHEN traffic_source IN ('email', 'e-mail', 'e_mail', 'e mail') OR traffic_medium IN ('email', 'e-mail', 'e_mail', 'e mail') THEN 'Email'
      WHEN traffic_medium = 'affiliate' THEN 'Affiliates'
      WHEN traffic_medium = 'audio' THEN 'Audio'
      WHEN traffic_source = 'sms' OR traffic_medium = 'sms' THEN 'SMS'
      WHEN traffic_medium LIKE '%push' OR REGEXP_CONTAINS(traffic_medium, r'(mobile|notification)') THEN 'Mobile Push Notifications'
      ELSE 'Unassigned'
    END AS Channel
  FROM
    sessions
)
GROUP BY
  Channel
ORDER BY
  Sessions DESC;