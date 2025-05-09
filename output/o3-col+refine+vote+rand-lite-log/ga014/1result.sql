/*  Traffic-channel sessions – December 2020  */

WITH session_start AS (
  /* one row per GA4 session */
  SELECT
    -- unique session id (user_pseudo_id + ga_session_id)
    CONCAT(
      user_pseudo_id ,'-',
      CAST( (
              SELECT ep.value.int_value
              FROM UNNEST(event_params) ep
              WHERE ep.key = 'ga_session_id'
            ) AS STRING)
    )                                            AS session_key ,

    -- pull source / medium / campaign from the hit-level parameters first,
    -- fall back on the traffic_source record, finally on GA default values
    COALESCE( (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'source'),
              traffic_source.source ,
              '(direct)' )                       AS source ,

    COALESCE( (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'medium'),
              traffic_source.medium ,
              '(none)' )                         AS medium ,

    COALESCE( (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'campaign'),
              traffic_source.name ,
              '' )                               AS campaign
  FROM  `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
),

channels AS (
  /* map every session to a Channel Group (replicates GA4 logic in short SQL) */
  SELECT
    session_key,
    source,
    medium,
    campaign,

    LOWER(source)   AS src_lc,
    LOWER(medium)   AS med_lc,
    LOWER(campaign) AS cmp_lc
  FROM session_start
),

mapped AS (
  SELECT
    session_key,

    CASE
      /* 1. Direct --------------------------------------------------------- */
      WHEN src_lc = '(direct)' AND med_lc IN ('(not set)', '(none)')        THEN 'Direct'

      /* 2. Paid channels -------------------------------------------------- */
      WHEN REGEXP_CONTAINS(cmp_lc , r'cross-network')                       THEN 'Cross-network'

      WHEN REGEXP_CONTAINS(med_lc , r'(.*cp.*|ppc|retargeting|paid.*)')
           AND REGEXP_CONTAINS(src_lc , r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
                                                                          THEN 'Paid Shopping'
      WHEN REGEXP_CONTAINS(med_lc , r'(.*cp.*|ppc|retargeting|paid.*)')
           AND REGEXP_CONTAINS(src_lc , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                                                                          THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(med_lc , r'(.*cp.*|ppc|retargeting|paid.*)')
           AND REGEXP_CONTAINS(src_lc , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                                                                          THEN 'Paid Social'
      WHEN REGEXP_CONTAINS(med_lc , r'(.*cp.*|ppc|retargeting|paid.*)')
           AND REGEXP_CONTAINS(src_lc , r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
                                                                          THEN 'Paid Video'

      /* 3. Display -------------------------------------------------------- */
      WHEN med_lc IN ('display','banner','expandable','interstitial','cpm') THEN 'Display'

      /* 4. Affiliates / Audio / Email / SMS / Push ------------------------ */
      WHEN med_lc = 'affiliate'                                            THEN 'Affiliates'
      WHEN med_lc = 'audio'                                                THEN 'Audio'
      WHEN med_lc IN ('email','e-mail','e_mail','e mail')
           OR src_lc IN ('email','e-mail','e_mail','e mail')               THEN 'Email'
      WHEN med_lc = 'sms' OR src_lc = 'sms'                                THEN 'SMS'
      WHEN med_lc LIKE '%push'
           OR REGEXP_CONTAINS(med_lc , r'(mobile|notification)')           THEN 'Mobile Push Notifications'

      /* 5. Organic Shopping / Social / Video ----------------------------- */
      WHEN REGEXP_CONTAINS(src_lc , r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
                                                                      THEN 'Organic Shopping'
      WHEN REGEXP_CONTAINS(src_lc , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR med_lc IN ('social','social-network','social-media','sm','social network','social media')
                                                                      THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(src_lc , r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(med_lc , r'video')                      THEN 'Organic Video'

      /* 6. Organic Search ------------------------------------------------- */
      WHEN med_lc = 'organic'
           OR REGEXP_CONTAINS(src_lc , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                                                                      THEN 'Organic Search'

      /* 7. Referral ------------------------------------------------------- */
      WHEN med_lc = 'referral'                                           THEN 'Referral'

      /* 8. Catch-all ------------------------------------------------------ */
      ELSE 'Unassigned'
    END AS channel_group
  FROM channels
)

SELECT
  channel_group,
  COUNT(DISTINCT session_key) AS total_sessions
FROM mapped
GROUP BY channel_group
ORDER BY total_sessions DESC;