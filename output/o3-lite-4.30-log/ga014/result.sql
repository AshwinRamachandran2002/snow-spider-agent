/*  December‑2020  GA4 sessions per traffic channel  */
WITH dec2020 AS (

    /* ----  explicit UNION of every December‑2020 daily table ---- */
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230` UNION ALL
    SELECT * FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`

),

/* ---------- one row per GA4 session ---------- */
sessions AS (
  SELECT
    /* unique session identifier (user_pseudo_id + ga_session_id) */
    CONCAT(
      user_pseudo_id, '-',
      CAST((
        SELECT ep.value.int_value
        FROM   UNNEST(event_params) ep
        WHERE  ep.key = 'ga_session_id'
      ) AS STRING)
    )                                             AS session_key,

    LOWER(
      COALESCE(
        (SELECT ep.value.string_value
         FROM   UNNEST(event_params) ep
         WHERE  ep.key = 'source'),
        traffic_source.source)
    )                                             AS source,

    LOWER(
      COALESCE(
        (SELECT ep.value.string_value
         FROM   UNNEST(event_params) ep
         WHERE  ep.key = 'medium'),
        traffic_source.medium)
    )                                             AS medium,

    LOWER(
      (SELECT ep.value.string_value
       FROM   UNNEST(event_params) ep
       WHERE  ep.key IN ('campaign', 'campaign_name')
       LIMIT 1)
    )                                             AS campaign
  FROM dec2020
  WHERE event_name = 'session_start'              -- exactly one event per session
),

/* ---------- map to traffic‑channel grouping ---------- */
classified AS (
  SELECT
    CASE
      WHEN source = '(direct)' AND medium IN ('(not set)', '(none)')                                 THEN 'Direct'
      WHEN campaign LIKE '%cross-network%'                                                           THEN 'Cross-network'
      WHEN REGEXP_CONTAINS(source, r'(alibaba|amazon|googleshopping|google shopping|shopify|etsy|ebay|stripe|walmart)')
           AND REGEXP_CONTAINS(medium, r'(.*cp.*|ppc|retargeting|paid.*)')                            THEN 'Paid Shopping'
      WHEN REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(medium, r'(.*cp.*|ppc|paid.*)')                                        THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(medium, r'(.*cp.*|ppc|retargeting|paid.*)')                            THEN 'Paid Social'
      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(medium, r'(.*cp.*|ppc|retargeting|paid.*)')                            THEN 'Paid Video'
      WHEN medium IN ('display','banner','expandable','interstitial','cpm')                          THEN 'Display'
      WHEN REGEXP_CONTAINS(source, r'(alibaba|amazon|googleshopping|google shopping|shopify|etsy|ebay|stripe|walmart)')
           OR REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])(shop|shopping)')                              THEN 'Organic Shopping'
      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR medium IN ('social','social-network','social-media','sm','social network','social media') THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(medium, r'video')                                                       THEN 'Organic Video'
      WHEN REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR medium = 'organic'                                                                      THEN 'Organic Search'
      WHEN medium = 'referral'                                                                        THEN 'Referral'
      WHEN source IN ('email','e-mail','e_mail','e mail') OR medium IN ('email','e-mail','e_mail','e mail') THEN 'Email'
      WHEN medium = 'affiliate'                                                                       THEN 'Affiliates'
      WHEN medium = 'audio'                                                                           THEN 'Audio'
      WHEN source = 'sms' OR medium = 'sms'                                                           THEN 'SMS'
      WHEN REGEXP_CONTAINS(medium, r'push$') OR REGEXP_CONTAINS(medium, r'(mobile|notification)')     THEN 'Mobile Push Notifications'
      ELSE 'Unassigned'
    END AS traffic_channel,
    session_key
  FROM sessions
)

/* ---------- final result ---------- */
SELECT
  traffic_channel,
  COUNT(DISTINCT session_key) AS total_sessions
FROM classified
GROUP BY traffic_channel
ORDER BY total_sessions DESC;