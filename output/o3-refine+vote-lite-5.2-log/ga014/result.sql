/*  Sessions by Default Channel Group – December 2020  */

WITH dec_sessions AS (
  -- pull every GA4 “session_start” event in December‑2020
  SELECT
    user_pseudo_id,

    -- GA4 session id (turn NULL to ‘’) – used for distinct‐session counting
    COALESCE(
      CAST(
        (SELECT value.int_value
         FROM UNNEST(event_params)
         WHERE key = 'ga_session_id'
         LIMIT 1) AS STRING
      ), ''
    )                                                     AS ga_session_id,

    -- traffic attributes kept in lower‑case for simpler pattern matching
    LOWER(COALESCE(
      (SELECT value.string_value
       FROM UNNEST(event_params)
       WHERE key = 'source'
       LIMIT 1), ''))                                     AS src,

    LOWER(COALESCE(
      (SELECT value.string_value
       FROM UNNEST(event_params)
       WHERE key = 'medium'
       LIMIT 1), ''))                                     AS med,

    LOWER(COALESCE(
      (SELECT value.string_value
       FROM UNNEST(event_params)
       WHERE key = 'campaign'
       LIMIT 1), ''))                                     AS cmp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
),

channelised AS (
  SELECT
    user_pseudo_id,
    ga_session_id,

    /* ----- Default Channel‑grouping logic (abridged to GA guidance) ----- */
    CASE
      WHEN src = '(direct)' AND med IN ('(not set)', '(none)')                THEN 'Direct'

      WHEN REGEXP_CONTAINS(cmp , r'cross[- ]?network')                        THEN 'Cross-network'

      WHEN ( REGEXP_CONTAINS(src, r'alibaba|amazon|google ?shopping|shopify|etsy|ebay|stripe|walmart')
             OR REGEXP_CONTAINS(cmp, r'(^|[^a-df-z])(shop|shopping)') )
           AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')             THEN 'Paid Shopping'

      WHEN REGEXP_CONTAINS(src, r'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
           AND REGEXP_CONTAINS(med, r'(cp|ppc|paid)')                         THEN 'Paid Search'

      WHEN REGEXP_CONTAINS(src, r'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
           AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')             THEN 'Paid Social'

      WHEN REGEXP_CONTAINS(src, r'dailymotion|disneyplus|netflix|youtube|vimeo|twitch')
           AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')             THEN 'Paid Video'

      WHEN med IN ('display','banner','expandable','interstitial','cpm')      THEN 'Display'

      WHEN ( REGEXP_CONTAINS(src, r'alibaba|amazon|google ?shopping|shopify|etsy|ebay|stripe|walmart')
             OR REGEXP_CONTAINS(cmp, r'(^|[^a-df-z])(shop|shopping)') )       THEN 'Organic Shopping'

      WHEN ( REGEXP_CONTAINS(src, r'badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp')
             OR med IN ('social','social-network','social-media','sm',
                         'social network','social media') )                  THEN 'Organic Social'

      WHEN ( REGEXP_CONTAINS(src, r'dailymotion|disneyplus|netflix|youtube|vimeo|twitch')
             OR REGEXP_CONTAINS(med, r'video') )                             THEN 'Organic Video'

      WHEN REGEXP_CONTAINS(src, r'baidu|bing|duckduckgo|ecosia|google|yahoo|yandex')
           OR med = 'organic'                                                THEN 'Organic Search'

      WHEN med = 'referral'                                                 THEN 'Referral'

      WHEN REGEXP_CONTAINS(src, r'email|e[-_ ]?mail') 
           OR REGEXP_CONTAINS(med, r'email|e[-_ ]?mail')                     THEN 'Email'

      WHEN med = 'affiliate'                                                THEN 'Affiliates'
      WHEN med = 'audio'                                                    THEN 'Audio'
      WHEN src = 'sms' OR med = 'sms'                                       THEN 'SMS'
      WHEN REGEXP_CONTAINS(med, r'push|mobile|notification')                THEN 'Mobile Push Notifications'

      ELSE 'Unassigned'
    END AS channel_grp
  FROM dec_sessions
)

SELECT
  channel_grp                                AS traffic_channel,
  COUNT(DISTINCT CONCAT(user_pseudo_id, '-', ga_session_id)) AS total_sessions
FROM channelised
GROUP BY channel_grp
ORDER BY total_sessions DESC;