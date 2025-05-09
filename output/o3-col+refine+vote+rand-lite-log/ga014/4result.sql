-- Traffic-channel session counts for December-2020
WITH dec_sessions AS (           -- 1. one row per GA4 session
  SELECT
    CONCAT(e.user_pseudo_id,'-',
           CAST(MAX(IF(ep.key='ga_session_id',ep.value.int_value,NULL)) AS STRING)
          )                                            AS session_id,
    LOWER(MAX(IF(ep.key='source'  ,ep.value.string_value,NULL))) AS source,
    LOWER(MAX(IF(ep.key='medium'  ,ep.value.string_value,NULL))) AS medium,
    LOWER(MAX(IF(ep.key='campaign',ep.value.string_value,NULL))) AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*` AS e
  CROSS JOIN UNNEST(e.event_params) AS ep
  WHERE e.event_name = 'session_start'                 -- only session starts
  GROUP BY e.user_pseudo_id, e.event_date
)
SELECT
  /* 2. Google-analytics channel-grouping logic */
  CASE
    WHEN source = '(direct)'
         AND (medium IS NULL OR medium IN ('(not set)','(none)',''))                     THEN 'Direct'

    WHEN campaign LIKE '%cross-network%'                                                 THEN 'Cross-network'

    WHEN (REGEXP_CONTAINS(source,r'(alibaba|amazon|shopping|shopify|etsy|ebay|stripe|walmart)')
           OR REGEXP_CONTAINS(campaign,r'(^.*(([^a-df-z]|^)shop|shopping).*$)'))
         AND REGEXP_CONTAINS(medium ,r'(cpc|ppc|retargeting|paid)')                      THEN 'Paid Shopping'

    WHEN REGEXP_CONTAINS(source ,r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
         AND REGEXP_CONTAINS(medium ,r'(cpc|ppc|paid)')                                  THEN 'Paid Search'

    WHEN REGEXP_CONTAINS(source ,r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
         AND REGEXP_CONTAINS(medium ,r'(cpc|ppc|retargeting|paid)')                      THEN 'Paid Social'

    WHEN REGEXP_CONTAINS(source ,r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
         AND REGEXP_CONTAINS(medium ,r'(cpc|ppc|retargeting|paid)')                      THEN 'Paid Video'

    WHEN medium IN ('display','banner','expandable','interstitial','cpm')                THEN 'Display'

    WHEN (REGEXP_CONTAINS(source,r'(alibaba|amazon|shopping|shopify|etsy|ebay|stripe|walmart)')
           OR REGEXP_CONTAINS(campaign,r'(^.*(([^a-df-z]|^)shop|shopping).*$)'))          THEN 'Organic Shopping'

    WHEN REGEXP_CONTAINS(source ,r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
         OR medium IN ('social','social-network','social-media','sm',
                       'social network','social media')                                  THEN 'Organic Social'

    WHEN REGEXP_CONTAINS(source ,r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
         OR REGEXP_CONTAINS(medium ,r'video')                                            THEN 'Organic Video'

    WHEN REGEXP_CONTAINS(source ,r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
         OR medium = 'organic'                                                           THEN 'Organic Search'

    WHEN medium = 'referral'                                                             THEN 'Referral'

    WHEN source IN ('email','e-mail','e_mail','e mail')
         OR medium IN ('email','e-mail','e_mail','e mail')                               THEN 'Email'

    WHEN medium = 'affiliate'                                                            THEN 'Affiliates'
    WHEN medium = 'audio'                                                                THEN 'Audio'
    WHEN source = 'sms' OR medium = 'sms'                                                THEN 'SMS'
    WHEN REGEXP_CONTAINS(medium,r'push$')
         OR REGEXP_CONTAINS(medium,r'(mobile|notification)')                             THEN 'Mobile Push Notifications'

    ELSE 'Unassigned'
  END AS channel_group,

  COUNT(DISTINCT session_id) AS sessions             -- 3. count sessions
FROM dec_sessions
GROUP BY channel_group
ORDER BY sessions DESC;