/*  Total sessions by GA-like “Channel group” – December 2020  */

WITH base AS (          -- pull 1 row per session_start
  SELECT
    -- user-pseudo-id + ga_session_id uniquely identify a GA4 session
    CONCAT(
      user_pseudo_id,
      CAST(
        ( SELECT value.int_value
          FROM UNNEST(event_params)
          WHERE key = 'ga_session_id'
          LIMIT 1
        ) AS STRING
      )
    )                                                AS session_key,

    -- raw Source / Medium / Campaign values, lower-cased
    LOWER(
      COALESCE(
        ( SELECT COALESCE(value.string_value,
                          CAST(value.int_value AS STRING))
          FROM UNNEST(event_params)
          WHERE key = 'source'
          LIMIT 1 ),
        '(direct)'
      )
    )                                                AS source,

    LOWER(
      COALESCE(
        ( SELECT COALESCE(value.string_value,
                          CAST(value.int_value AS STRING))
          FROM UNNEST(event_params)
          WHERE key = 'medium'
          LIMIT 1 ),
        '(not set)'
      )
    )                                                AS medium,

    LOWER(
      COALESCE(
        ( SELECT COALESCE(value.string_value,
                          CAST(value.int_value AS STRING))
          FROM UNNEST(event_params)
          WHERE key = 'campaign'
          LIMIT 1 ),
        ''
      )
    )                                                AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name = 'session_start'
),

classified AS (        -- translate to channel definitions
  SELECT
    session_key,
    CASE
      -- 1. Direct
      WHEN source = '(direct)'
           AND medium IN ('(not set)','(none)','')                 THEN 'Direct'

      -- 2. Cross-network
      WHEN campaign LIKE '%cross-network%'                         THEN 'Cross-network'

      -- 3. Paid channels
      WHEN REGEXP_CONTAINS(source, r'(alibaba|amazon|google[ _]shopping|shopify|etsy|ebay|stripe|walmart)')
           AND REGEXP_CONTAINS(medium,  r'(cp|ppc|paid|retargeting|cpc)')
                                                                THEN 'Paid Shopping'
      WHEN REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(medium,  r'(cp|ppc|paid|retargeting|cpc)')
                                                                THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(medium,  r'(cp|ppc|paid|retargeting|cpc)')
                                                                THEN 'Paid Social'
      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(medium,  r'(cp|ppc|paid|retargeting|cpc)')
                                                                THEN 'Paid Video'

      -- 4. Display
      WHEN medium IN ('display','banner','expandable','interstitial','cpm')
           OR medium LIKE '%display%'                           THEN 'Display'

      -- 5. Other paid / partner channels
      WHEN medium = 'affiliate'                                 THEN 'Affiliates'
      WHEN source IN ('email','e-mail','e_mail','e mail')
           OR medium IN ('email','e-mail','e_mail','e mail')    THEN 'Email'
      WHEN medium = 'audio'                                    THEN 'Audio'
      WHEN source = 'sms' OR medium = 'sms'                    THEN 'SMS'
      WHEN REGEXP_CONTAINS(medium, r'(push$|mobile|notification)')
                                                                THEN 'Mobile Push Notifications'

      -- 6. Referral
      WHEN medium = 'referral'                                 THEN 'Referral'

      -- 7. Organic channels
      WHEN REGEXP_CONTAINS(source, r'(alibaba|amazon|google[ _]shopping|shopify|etsy|ebay|stripe|walmart)')
                                                                THEN 'Organic Shopping'
      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR medium IN ('social','social-network','social-media','sm','social network','social media')
                                                                THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(medium, r'video')                THEN 'Organic Video'
      WHEN medium = 'organic'
           OR REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                                                                THEN 'Organic Search'

      -- 8. Default
      ELSE 'Unassigned'
    END AS channel_group
  FROM base
)

SELECT
  channel_group,
  COUNT(DISTINCT session_key) AS total_sessions
FROM classified
GROUP BY channel_group
ORDER BY total_sessions DESC;