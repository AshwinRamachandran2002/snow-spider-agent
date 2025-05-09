-- 4th‑largest traffic‑channel by number of sessions in December‑2020
WITH sessions AS (
  -- one row per session (defined by session_start event)
  SELECT
    user_pseudo_id,
    -- session id is stored in event_params → key = 'ga_session_id'
    ( SELECT ep.value.int_value
      FROM   UNNEST(event_params) ep
      WHERE  ep.key = 'ga_session_id')          AS session_id,
    LOWER(traffic_source.source)               AS src,
    LOWER(traffic_source.medium)               AS med,
    LOWER(traffic_source.name)                 AS camp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'   -- December 2020
    AND event_name = 'session_start'
),
ch_sessions AS (
  -- channel grouping rules
  SELECT
    CASE
      WHEN src = '(direct)' AND med IN ('(not set)', '(none)')                        THEN 'Direct'
      WHEN REGEXP_CONTAINS(camp, r'cross[- ]?network')                                THEN 'Cross-network'
      WHEN (REGEXP_CONTAINS(src, r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
            OR REGEXP_CONTAINS(camp, r'(\bshop\b|shopping)'))
           AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')                      THEN 'Paid Shopping'
      WHEN REGEXP_CONTAINS(src, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(med, r'(cp|ppc|paid)')                                  THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(src, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')                      THEN 'Paid Social'
      WHEN REGEXP_CONTAINS(src, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(med, r'(cp|ppc|retargeting|paid)')                      THEN 'Paid Video'
      WHEN med IN ('display','banner','expandable','interstitial','cpm')               THEN 'Display'
      WHEN (REGEXP_CONTAINS(src, r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
            OR REGEXP_CONTAINS(camp, r'(\bshop\b|shopping)'))                          THEN 'Organic Shopping'
      WHEN REGEXP_CONTAINS(src, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR med IN ('social','social-network','social-media','sm',
                       'social network','social media')                                THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(src, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(med, r'video')                                           THEN 'Organic Video'
      WHEN REGEXP_CONTAINS(src, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR med = 'organic'                                                          THEN 'Organic Search'
      WHEN med = 'referral'                                                            THEN 'Referral'
      WHEN src IN ('email','e-mail','e_mail','e mail')
           OR med IN ('email','e-mail','e_mail','e mail')                              THEN 'Email'
      WHEN med = 'affiliate'                                                           THEN 'Affiliates'
      WHEN med = 'audio'                                                               THEN 'Audio'
      WHEN src = 'sms' OR med = 'sms'                                                  THEN 'SMS'
      WHEN REGEXP_CONTAINS(med, r'push$')
           OR REGEXP_CONTAINS(med, r'(mobile|notification)')                           THEN 'Mobile Push Notifications'
      ELSE 'Unassigned'
    END                                                             AS channel,
    COUNT(DISTINCT CONCAT(user_pseudo_id,'-',CAST(session_id AS STRING))) AS sessions
  FROM sessions
  WHERE session_id IS NOT NULL
  GROUP BY channel
),
ranked AS (
  SELECT channel,
         sessions,
         DENSE_RANK() OVER (ORDER BY sessions DESC) AS rnk
  FROM   ch_sessions
)
SELECT channel   AS fourth_highest_channel,
       sessions
FROM   ranked
WHERE  rnk = 4
ORDER  BY sessions DESC;