/*  Total number of sessions (unique user_pseudo_id + ga_session_id)
    broken down by default channel group – December 2020              */

WITH sessions AS (
  /* pull one record per (user_pseudo_id , ga_session_id)   */
  SELECT
    user_pseudo_id,
    ga_session_id,
    COALESCE(LOWER(MAX(IF(src IS NOT NULL , src , NULL))), '') AS src,
    COALESCE(LOWER(MAX(IF(med IS NOT NULL , med , NULL))), '') AS med,
    COALESCE(LOWER(MAX(IF(cmp IS NOT NULL , cmp , NULL))), '') AS cmp
  FROM (
    SELECT
      user_pseudo_id,

      /* extract needed event‑parameters */
      (SELECT ep.value.int_value
       FROM   UNNEST(event_params) ep
       WHERE  ep.key = 'ga_session_id')            AS ga_session_id,

      (SELECT ep.value.string_value
       FROM   UNNEST(event_params) ep
       WHERE  ep.key = 'source')                   AS src,

      (SELECT ep.value.string_value
       FROM   UNNEST(event_params) ep
       WHERE  ep.key = 'medium')                   AS med,

      (SELECT ep.value.string_value
       FROM   UNNEST(event_params) ep
       WHERE  ep.key = 'campaign')                 AS cmp
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
    WHERE event_date BETWEEN '20201201' AND '20201231'
  )
  WHERE ga_session_id IS NOT NULL                             -- keep only valid sessions
  GROUP BY user_pseudo_id, ga_session_id
),

channels AS (
  /* map every session to one default channel group */
  SELECT
    user_pseudo_id,
    ga_session_id,

    CASE
      WHEN src = '(direct)' AND med IN ('', '(not set)', '(none)')                THEN 'Direct'
      WHEN cmp LIKE '%cross-network%'                                             THEN 'Cross-network'

      WHEN (REGEXP_CONTAINS(src , r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
            OR REGEXP_CONTAINS(cmp , r'(^.*(([^a-df-z]|^)shop|shopping).*)'))
           AND REGEXP_CONTAINS(med , r'(cp|ppc|retargeting|paid)')                THEN 'Paid Shopping'

      WHEN REGEXP_CONTAINS(src , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(med , r'(cp|ppc|retargeting|paid)')                THEN 'Paid Search'

      WHEN REGEXP_CONTAINS(src , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(med , r'(cp|ppc|retargeting|paid)')                THEN 'Paid Social'

      WHEN REGEXP_CONTAINS(src , r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(med , r'(cp|ppc|retargeting|paid)')                THEN 'Paid Video'

      WHEN med IN ('display','banner','expandable','interstitial','cpm')          THEN 'Display'

      WHEN REGEXP_CONTAINS(src , r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
           OR REGEXP_CONTAINS(cmp , r'(^.*(([^a-df-z]|^)shop|shopping).*)')       THEN 'Organic Shopping'

      WHEN REGEXP_CONTAINS(src , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR med IN ('social','social-network','social-media','sm',
                      'social network','social media')                            THEN 'Organic Social'

      WHEN REGEXP_CONTAINS(src , r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(med , r'video')                                     THEN 'Organic Video'

      WHEN REGEXP_CONTAINS(src , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR med = 'organic'                                                     THEN 'Organic Search'

      WHEN med = 'referral'                                                       THEN 'Referral'
      WHEN src IN ('email','e-mail','e_mail','e mail')
        OR med IN ('email','e-mail','e_mail','e mail')                            THEN 'Email'
      WHEN med = 'affiliate'                                                      THEN 'Affiliates'
      WHEN med = 'audio'                                                          THEN 'Audio'
      WHEN src = 'sms' OR med = 'sms'                                             THEN 'SMS'
      WHEN REGEXP_CONTAINS(med , r'(push$|mobile|notification)')                  THEN 'Mobile Push Notifications'

      ELSE 'Unassigned'
    END AS traffic_channel
  FROM sessions
)

SELECT
  traffic_channel,
  COUNT(*) AS sessions
FROM channels
GROUP BY traffic_channel
ORDER BY sessions DESC;