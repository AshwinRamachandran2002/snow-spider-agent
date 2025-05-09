-- Total number of sessions for each traffic channel in December‑2020
SELECT
  channel,
  COUNT(DISTINCT session_key) AS sessions_dec_2020
FROM (
  -- build one row per GA4 session with source / medium / campaign
  SELECT
    CONCAT(user_pseudo_id, '-', CAST(ga_session_id AS STRING)) AS session_key,
    CASE
      -- ❶ Direct
      WHEN source = '(direct)'
           AND (medium IN ('(not set)', '(none)', '') OR medium IS NULL)                           THEN 'Direct'

      -- ❷ Referral
      WHEN medium = 'referral'                                                                    THEN 'Referral'

      -- ❸ Display
      WHEN REGEXP_CONTAINS(medium , r'(display|banner|expandable|interstitial|cpm)')              THEN 'Display'

      -- ❹ Paid channels
      WHEN REGEXP_CONTAINS(source , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')                             THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(source , r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')                             THEN 'Paid Shopping'
      WHEN REGEXP_CONTAINS(source , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')                             THEN 'Paid Social'
      WHEN REGEXP_CONTAINS(source , r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')                             THEN 'Paid Video'

      -- ❺ Organic channels
      WHEN REGEXP_CONTAINS(source , r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
           OR REGEXP_CONTAINS(campaign , r'(shop|shopping)')                                      THEN 'Organic Shopping'
      WHEN REGEXP_CONTAINS(source , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR medium IN ('social', 'social-network', 'social-media', 'sm',
                         'social network', 'social media')                                        THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(source , r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(medium , r'video')                                                  THEN 'Organic Video'
      WHEN REGEXP_CONTAINS(source , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR medium = 'organic'                                                                  THEN 'Organic Search'

      -- ❻ Everything else
      ELSE 'Unassigned'
    END AS channel
  FROM (
    -- pull raw fields from GA4 event parameters
    SELECT
      user_pseudo_id,

      -- GA session id (integer)
      (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id'
       LIMIT 1) AS ga_session_id,

      LOWER((SELECT ep.value.string_value
             FROM UNNEST(event_params) ep
             WHERE ep.key = 'source'
             LIMIT 1)) AS source,

      LOWER((SELECT ep.value.string_value
             FROM UNNEST(event_params) ep
             WHERE ep.key = 'medium'
             LIMIT 1)) AS medium,

      LOWER((SELECT ep.value.string_value
             FROM UNNEST(event_params) ep
             WHERE ep.key = 'campaign'
             LIMIT 1)) AS campaign
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
    WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'          -- December 2020
      AND event_name = 'session_start'                 -- one record per session
  )
)
GROUP BY channel
ORDER BY sessions_dec_2020 DESC;