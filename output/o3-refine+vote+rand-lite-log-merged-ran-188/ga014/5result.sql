/*  Total GA4 sessions per default traffic‑channel for December‑2020  */
WITH sessions AS (
  SELECT
    /* every session_start row represents one session */
    (SELECT value.int_value
       FROM UNNEST(event_params)
      WHERE key = 'ga_session_id')                     AS ga_session_id,
    user_pseudo_id,

    -- traffic‐source attributes (lower‑cased for easy tests)
    LOWER(COALESCE(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source'), ''))  AS src,
    LOWER(COALESCE(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium'), ''))  AS med,
    LOWER(COALESCE(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign'), '')) AS cmp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  -- suffix is the two‑digit day (01‑31) because the wildcard already fixes the month
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'
    AND event_name = 'session_start'
),

channels AS (
  SELECT
    ga_session_id,
    user_pseudo_id,
    CASE
      WHEN src = '(direct)' AND med IN ('(not set)', '(none)', '')                     THEN 'Direct'
      WHEN REGEXP_CONTAINS(cmp , r"cross[- ]?network")                                 THEN 'Cross-network'

      WHEN (REGEXP_CONTAINS(src, r"(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)")
            OR REGEXP_CONTAINS(cmp, r"(^|[^a-df-z])(shop|shopping)"))
           AND REGEXP_CONTAINS(med, r"(cp|ppc|retargeting|paid)")                      THEN 'Paid Shopping'

      WHEN REGEXP_CONTAINS(src, r"(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)")
           AND REGEXP_CONTAINS(med, r"(cp|ppc|paid)")                                  THEN 'Paid Search'

      WHEN REGEXP_CONTAINS(src, r"(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)")
           AND REGEXP_CONTAINS(med, r"(cp|ppc|retargeting|paid)")                      THEN 'Paid Social'

      WHEN REGEXP_CONTAINS(src, r"(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)")
           AND REGEXP_CONTAINS(med, r"(cp|ppc|retargeting|paid)")                      THEN 'Paid Video'

      WHEN med IN ('display','banner','expandable','interstitial','cpm')               THEN 'Display'

      WHEN (REGEXP_CONTAINS(src, r"(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)")
            OR REGEXP_CONTAINS(cmp, r"(^|[^a-df-z])(shop|shopping)"))                  THEN 'Organic Shopping'

      WHEN REGEXP_CONTAINS(src, r"(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)")
           OR med IN ('social','social-network','social-media','sm',
                       'social network','social media')                               THEN 'Organic Social'

      WHEN REGEXP_CONTAINS(src, r"(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)")
           OR REGEXP_CONTAINS(med, r"video")                                          THEN 'Organic Video'

      WHEN REGEXP_CONTAINS(src, r"(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)")
           OR med = 'organic'                                                          THEN 'Organic Search'

      WHEN med = 'referral'                                                            THEN 'Referral'
      WHEN src IN ('email','e-mail','e_mail','e mail')
        OR med IN ('email','e-mail','e_mail','e mail')                                 THEN 'Email'
      WHEN med = 'affiliate'                                                           THEN 'Affiliates'
      WHEN med = 'audio'                                                               THEN 'Audio'
      WHEN src = 'sms' OR med = 'sms'                                                  THEN 'SMS'
      WHEN REGEXP_CONTAINS(med, r"(push$|mobile|notification)")                        THEN 'Mobile Push Notifications'
      ELSE 'Unassigned'
    END AS channel
  FROM sessions
)

SELECT
  channel,
  COUNT(*) AS total_sessions
FROM channels
GROUP BY channel
ORDER BY total_sessions DESC;