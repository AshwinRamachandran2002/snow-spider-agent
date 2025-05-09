SELECT
  traffic_channel,
  COUNT(*) AS Sessions
FROM (
  SELECT
    CASE
      WHEN COALESCE(source, '') = '(direct)' AND COALESCE(medium, '') IN ('(not set)', '(none)', '')
        THEN 'Direct'
      WHEN LOWER(COALESCE(medium, '')) = 'referral'
        THEN 'Referral'
      WHEN LOWER(COALESCE(medium, '')) IN ('email', 'e-mail', 'e_mail', 'e mail') OR LOWER(COALESCE(source, '')) IN ('email', 'e-mail', 'e_mail', 'e mail')
        THEN 'Email'
      WHEN LOWER(COALESCE(medium, '')) = 'affiliate'
        THEN 'Affiliates'
      WHEN LOWER(COALESCE(medium, '')) = 'audio'
        THEN 'Audio'
      WHEN LOWER(COALESCE(source, '')) = 'sms' OR LOWER(COALESCE(medium, '')) = 'sms'
        THEN 'SMS'
      WHEN LOWER(COALESCE(medium, '')) LIKE '%push%' OR LOWER(COALESCE(medium, '')) LIKE '%mobile%' OR LOWER(COALESCE(medium, '')) LIKE '%notification%'
        THEN 'Mobile Push Notifications'
      WHEN 
        LOWER(COALESCE(source, '')) IN ('baidu', 'bing', 'duckduckgo', 'ecosia', 'google', 'yahoo', 'yandex') AND
        REGEXP_CONTAINS(LOWER(COALESCE(medium, '')), r'(.*cp.*|ppc|paid.*)')
        THEN 'Paid Search'
      WHEN 
        REGEXP_CONTAINS(LOWER(COALESCE(source, '')), r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)') AND
        REGEXP_CONTAINS(LOWER(COALESCE(medium, '')), r'(.*cp.*|ppc|retargeting|paid.*)')
        THEN 'Paid Social'
      WHEN 
        LOWER(COALESCE(source, '')) IN ('dailymotion', 'disneyplus', 'netflix', 'youtube', 'vimeo', 'twitch') AND
        REGEXP_CONTAINS(LOWER(COALESCE(medium, '')), r'(.*cp.*|ppc|retargeting|paid.*)')
        THEN 'Paid Video'
      WHEN LOWER(COALESCE(medium, '')) IN ('display', 'banner', 'expandable', 'interstitial', 'cpm')
        THEN 'Display'
      WHEN 
        (REGEXP_CONTAINS(LOWER(COALESCE(source, '')), r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)') OR
         REGEXP_CONTAINS(LOWER(COALESCE(campaign, '')), r'(shop|shopping)')) AND
        REGEXP_CONTAINS(LOWER(COALESCE(medium, '')), r'(.*cp.*|ppc|retargeting|paid.*)')
        THEN 'Paid Shopping'
      WHEN 
        REGEXP_CONTAINS(LOWER(COALESCE(source, '')), r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)') OR
        REGEXP_CONTAINS(LOWER(COALESCE(campaign, '')), r'(shop|shopping)')
        THEN 'Organic Shopping'
      WHEN 
        LOWER(COALESCE(medium, '')) = 'organic' OR
        LOWER(COALESCE(source, '')) IN ('baidu', 'bing', 'duckduckgo', 'ecosia', 'google', 'yahoo', 'yandex')
        THEN 'Organic Search'
      WHEN 
        REGEXP_CONTAINS(LOWER(COALESCE(source, '')), r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)') OR
        LOWER(COALESCE(medium, '')) IN ('social', 'social-network', 'social-media', 'sm', 'social network', 'social media')
        THEN 'Organic Social'
      WHEN 
        LOWER(COALESCE(source, '')) IN ('dailymotion', 'disneyplus', 'netflix', 'youtube', 'vimeo', 'twitch') OR
        LOWER(COALESCE(medium, '')) LIKE '%video%'
        THEN 'Organic Video'
      ELSE 'Unassigned'
    END AS traffic_channel
  FROM (
    SELECT
      e.event_name,
      e.event_timestamp,
      COALESCE(e.traffic_source.source,
               MAX(IF(ep.key = 'source', ep.value.string_value, NULL))) AS source,
      COALESCE(e.traffic_source.medium,
               MAX(IF(ep.key = 'medium', ep.value.string_value, NULL))) AS medium,
      COALESCE(e.traffic_source.name,
               MAX(IF(ep.key = 'campaign', ep.value.string_value, NULL))) AS campaign
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS e
    LEFT JOIN UNNEST(e.event_params) AS ep
    ON TRUE
    WHERE e.event_name = 'session_start'
    GROUP BY e.event_name, e.event_timestamp, e.traffic_source
  )
)
GROUP BY traffic_channel
ORDER BY Sessions DESC;