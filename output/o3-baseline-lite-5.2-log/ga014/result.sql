-- Total number of GA4 sessions (Dec‑2020) by Default Channel Group
WITH dec20_sessions AS (
  SELECT
    -- build a unique session identifier
    CONCAT(
      SAFE_CAST((
        SELECT value.int_value
        FROM UNNEST(event_params)
        WHERE key = 'ga_session_id'
        LIMIT 1
      ) AS STRING),
      '-', user_pseudo_id
    )                                              AS session_id,

    LOWER(
      COALESCE((
        SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'source'
        LIMIT 1
      ), '')
    )                                              AS src,

    LOWER(
      COALESCE((
        SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'medium'
        LIMIT 1
      ), '')
    )                                              AS med,

    LOWER(
      COALESCE((
        SELECT value.string_value
        FROM UNNEST(event_params)
        WHERE key = 'campaign'
        LIMIT 1
      ), '')
    )                                              AS cmp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  -- the “session_start” event is logged exactly once per session
  WHERE event_name = 'session_start'
),

classified AS (
  SELECT
    session_id,

    CASE
        -- Direct
        WHEN src = '(direct)'
             AND med IN ('', '(none)', '(not set)')                                        THEN 'Direct'

        -- Cross‑network
        WHEN REGEXP_CONTAINS(cmp, r'cross[-_ ]?network')                                   THEN 'Cross-network'

        -- Paid Shopping
        WHEN (REGEXP_CONTAINS(src, r'(alibaba|amazon|shopping|shopify|etsy|ebay|stripe|walmart)')
              OR REGEXP_CONTAINS(cmp, r'(^|[^a-df-z])(shop|shopping)'))
             AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')                        THEN 'Paid Shopping'

        -- Paid Search
        WHEN REGEXP_CONTAINS(src, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
             AND REGEXP_CONTAINS(med, r'(cp|ppc|paid)')                                    THEN 'Paid Search'

        -- Paid Social
        WHEN REGEXP_CONTAINS(src, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
             AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')                        THEN 'Paid Social'

        -- Paid Video
        WHEN REGEXP_CONTAINS(src, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
             AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')                        THEN 'Paid Video'

        -- Display
        WHEN med IN ('display','banner','expandable','interstitial','cpm')                 THEN 'Display'

        -- Organic Shopping
        WHEN (REGEXP_CONTAINS(src, r'(alibaba|amazon|shopping|shopify|etsy|ebay|stripe|walmart)')
              OR REGEXP_CONTAINS(cmp, r'(^|[^a-df-z])(shop|shopping)'))                    THEN 'Organic Shopping'

        -- Organic Social
        WHEN REGEXP_CONTAINS(src, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
             OR med IN ('social','social-network','social-media','sm',
                         'social network','social media')                                  THEN 'Organic Social'

        -- Organic Video
        WHEN REGEXP_CONTAINS(src, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
             OR REGEXP_CONTAINS(med, r'video')                                             THEN 'Organic Video'

        -- Organic Search
        WHEN REGEXP_CONTAINS(src, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
             OR med = 'organic'                                                            THEN 'Organic Search'

        -- Referral
        WHEN med = 'referral'                                                              THEN 'Referral'

        -- Email
        WHEN src IN ('email','e-mail','e_mail','e mail')
             OR med IN ('email','e-mail','e_mail','e mail')                                THEN 'Email'

        -- Affiliates
        WHEN med = 'affiliate'                                                             THEN 'Affiliates'

        -- Audio
        WHEN med = 'audio'                                                                 THEN 'Audio'

        -- SMS
        WHEN src = 'sms' OR med = 'sms'                                                    THEN 'SMS'

        -- Mobile Push
        WHEN med LIKE '%push'
             OR REGEXP_CONTAINS(med, r'(mobile|notification)')                             THEN 'Mobile Push Notifications'

        -- Everything else
        ELSE 'Unassigned'
    END AS channel
  FROM dec20_sessions
  WHERE session_id IS NOT NULL
)

SELECT
  channel,
  COUNT(DISTINCT session_id) AS total_sessions
FROM classified
GROUP BY channel
ORDER BY total_sessions DESC;