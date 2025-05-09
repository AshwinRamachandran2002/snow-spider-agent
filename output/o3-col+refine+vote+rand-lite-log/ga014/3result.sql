/*  Sessions by traffic-channel  |  December-2020  */

WITH raw_sessions AS (
  SELECT
    LOWER( (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'source') ) AS src,
    LOWER( (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'medium') ) AS med
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
)

SELECT
  CASE
      -- Direct
      WHEN src = '(direct)' AND med IN ('(not set)', '(none)')                                      THEN 'Direct'

      -- Paid channels
      WHEN REGEXP_CONTAINS(src, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(med, r'(cp|ppc|paid)')                                               THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(src, r'(alibaba|amazon|googleshopping|shopify|etsy|ebay|stripe|walmart)')
           AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')                                    THEN 'Paid Shopping'
      WHEN REGEXP_CONTAINS(src, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')                                    THEN 'Paid Social'
      WHEN REGEXP_CONTAINS(src, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')                                    THEN 'Paid Video'
      WHEN med IN ('display','banner','expandable','interstitial','cpm')                            THEN 'Display'

      -- Organic channels
      WHEN REGEXP_CONTAINS(src, r'(alibaba|amazon|googleshopping|shopify|etsy|ebay|stripe|walmart)')
           OR (REGEXP_CONTAINS(src, r'(shop|shopping)') AND med = 'organic')                         THEN 'Organic Shopping'
      WHEN REGEXP_CONTAINS(src, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR med IN ('social','social-network','social-media','sm','social network','social media') THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(src, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(med, r'video')                                                        THEN 'Organic Video'
      WHEN REGEXP_CONTAINS(src, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR med = 'organic'                                                                       THEN 'Organic Search'

      -- Other explicit channels
      WHEN med = 'referral'                                                                         THEN 'Referral'
      WHEN src IN ('email','e-mail','e_mail','e mail') OR med IN ('email','e-mail','e_mail','e mail') THEN 'Email'
      WHEN med = 'affiliate'                                                                        THEN 'Affiliates'
      WHEN med = 'audio'                                                                            THEN 'Audio'
      WHEN src = 'sms' OR med = 'sms'                                                               THEN 'SMS'
      WHEN RIGHT(med,4) = 'push' OR REGEXP_CONTAINS(med, r'(mobile|notification)')                  THEN 'Mobile Push Notifications'
      WHEN REGEXP_CONTAINS(src, r'cross-network')                                                   THEN 'Cross-network'

      -- Catch-all
      ELSE 'Unassigned'
  END AS channel_group,
  COUNT(*) AS total_sessions
FROM raw_sessions
GROUP BY channel_group
ORDER BY total_sessions DESC;