/*  Total number of sessions per traffic‑channel
    for December 2020 – GA4 sample e‑commerce export           */

WITH sessions AS (   -- 1 row = 1 session_start event
  SELECT DISTINCT
         user_pseudo_id,

         -- session identifier
         (SELECT ep.value.int_value
            FROM UNNEST(event_params) ep
           WHERE ep.key = 'ga_session_id')                    AS ga_session_id,

         /* traffic attributes (lower‑case for matching) */
         LOWER(
           COALESCE(
             (SELECT ep.value.string_value
                FROM UNNEST(event_params) ep
               WHERE ep.key = 'source'),
             '(not set)')
         )                                                    AS source,

         LOWER(
           COALESCE(
             (SELECT ep.value.string_value
                FROM UNNEST(event_params) ep
               WHERE ep.key = 'medium'),
             '(not set)')
         )                                                    AS medium,

         LOWER(
           COALESCE(
             (SELECT ep.value.string_value
                FROM UNNEST(event_params) ep
               WHERE ep.key = 'campaign'),
             '')
         )                                                    AS campaign
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_date BETWEEN '20201201' AND '20201231'
    AND event_name = 'session_start'
    AND EXISTS (SELECT 1 FROM UNNEST(event_params) ep WHERE ep.key = 'ga_session_id')
),

channelised AS (      -- apply channel‑grouping rules
  SELECT
    user_pseudo_id,
    ga_session_id,
    CASE
      WHEN source = '(direct)' AND medium IN ('(not set)','(none)')
                                                            THEN 'Direct'
      WHEN REGEXP_CONTAINS(campaign , r'cross-network')     THEN 'Cross-network'

      WHEN (REGEXP_CONTAINS(source , r'(alibaba|amazon|etsy|ebay|stripe|walmart|shopify|google shopping)')
            OR REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])shop|shopping'))
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')
                                                            THEN 'Paid Shopping'

      WHEN REGEXP_CONTAINS(source , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|paid)')   THEN 'Paid Search'

      WHEN REGEXP_CONTAINS(source , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')
                                                            THEN 'Paid Social'

      WHEN REGEXP_CONTAINS(source , r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')
                                                            THEN 'Paid Video'

      WHEN medium IN ('display','banner','expandable','interstitial','cpm')
                                                            THEN 'Display'

      WHEN REGEXP_CONTAINS(source , r'(alibaba|amazon|etsy|ebay|stripe|walmart|shopify|google shopping)')
           OR REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])shop|shopping')
                                                            THEN 'Organic Shopping'

      WHEN REGEXP_CONTAINS(source , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR medium IN ('social','social-network','social-media','sm','social network','social media')
                                                            THEN 'Organic Social'

      WHEN REGEXP_CONTAINS(source , r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(medium , r'video')            THEN 'Organic Video'

      WHEN REGEXP_CONTAINS(source , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR medium = 'organic'                            THEN 'Organic Search'

      WHEN medium = 'referral'                              THEN 'Referral'

      WHEN source IN ('email','e-mail','e_mail','e mail')
        OR medium IN ('email','e-mail','e_mail','e mail')   THEN 'Email'

      WHEN medium = 'affiliate'                             THEN 'Affiliates'
      WHEN medium = 'audio'                                 THEN 'Audio'
      WHEN source = 'sms' OR medium = 'sms'                 THEN 'SMS'
      WHEN REGEXP_CONTAINS(medium , r'(push$)|(mobile)|(notification)')
                                                            THEN 'Mobile Push Notifications'
      ELSE 'Unassigned'
    END AS traffic_channel
  FROM sessions
)

SELECT
  traffic_channel,
  COUNT(DISTINCT CONCAT(user_pseudo_id,'-',CAST(ga_session_id AS STRING))) AS total_sessions
FROM channelised
GROUP BY traffic_channel
ORDER BY total_sessions DESC;