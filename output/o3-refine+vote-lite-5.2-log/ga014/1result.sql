-- Total number of sessions per traffic‑channel for December‑2020
WITH base AS (     -- pull the pieces we need from every Dec‑2020 day
  SELECT
    user_pseudo_id,
    ( SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id')                           AS ga_session_id,
    LOWER(
      COALESCE(
        (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'medium'),
        '')
    )                                                           AS medium,
    LOWER(
      COALESCE(
        (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'source'),
        '')
    )                                                           AS source,
    LOWER(
      COALESCE(
        (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'campaign'),
        '')
    )                                                           AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'          -- safety: only December tables
),
classified AS (        -- turn source / medium / campaign into a channel group
  SELECT
    user_pseudo_id,
    ga_session_id,
    CASE
      WHEN source = '(direct)' AND medium IN ('(not set)', '(none)', '')                              THEN 'Direct'
      WHEN REGEXP_CONTAINS(campaign,        r'cross-network')                                         THEN 'Cross-network'

      WHEN (REGEXP_CONTAINS(source,   r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
            OR REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])shop|shopping'))
           AND REGEXP_CONTAINS(medium,   r'(cp|ppc|retargeting|paid)')                                 THEN 'Paid Shopping'

      WHEN REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|paid)')                                               THEN 'Paid Search'

      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|retargeting|paid)')                                   THEN 'Paid Social'

      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|retargeting|paid)')                                   THEN 'Paid Video'

      WHEN medium IN ('display','banner','expandable','interstitial','cpm')                           THEN 'Display'

      WHEN (REGEXP_CONTAINS(source,   r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
            OR REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])shop|shopping'))                                THEN 'Organic Shopping'

      WHEN (REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
            OR medium IN ('social','social-network','social-media','sm','social network','social media')) THEN 'Organic Social'

      WHEN (REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
            OR REGEXP_CONTAINS(medium, r'video'))                                                      THEN 'Organic Video'

      WHEN REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR medium = 'organic'                                                                       THEN 'Organic Search'

      WHEN medium = 'referral'                                                                         THEN 'Referral'
      WHEN source IN ('email','e-mail','e_mail','e mail')
           OR medium IN ('email','e-mail','e_mail','e mail')                                           THEN 'Email'
      WHEN medium = 'affiliate'                                                                        THEN 'Affiliates'
      WHEN medium = 'audio'                                                                            THEN 'Audio'
      WHEN source = 'sms' OR medium = 'sms'                                                            THEN 'SMS'
      WHEN REGEXP_CONTAINS(medium, r'push$')
           OR REGEXP_CONTAINS(medium, r'(mobile|notification)')                                        THEN 'Mobile Push Notifications'
      ELSE 'Unassigned'
    END AS channel
  FROM base
  WHERE ga_session_id IS NOT NULL                -- ignore events lacking a session id
),
distinct_sessions AS (   -- one row per unique GA4 session
  SELECT DISTINCT
    user_pseudo_id,
    ga_session_id,
    channel
  FROM classified
)
SELECT
  channel,
  COUNT(*) AS sessions
FROM distinct_sessions
GROUP BY channel
ORDER BY sessions DESC;