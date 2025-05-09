WITH dec2020 AS (
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201201` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201202` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201203` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201204` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201205` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201206` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201207` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201208` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201209` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201210` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201211` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201212` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201213` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201214` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201215` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201216` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201217` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201218` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201219` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201220` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201221` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201222` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201223` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201224` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201225` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201226` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201227` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201228` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201229` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201230` UNION ALL
    SELECT user_pseudo_id, event_name, traffic_source, event_params
      FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20201231`
),
session_rows AS (
    SELECT
        user_pseudo_id,
        (SELECT ep.value.int_value
           FROM UNNEST(event_params) ep
          WHERE ep.key = 'ga_session_id')                   AS ga_session_id,
        LOWER(COALESCE(traffic_source.source , ''))         AS src,
        LOWER(COALESCE(traffic_source.medium, ''))          AS med
    FROM dec2020
    WHERE event_name = 'session_start'
),
sessions AS (
    SELECT DISTINCT user_pseudo_id, ga_session_id, src, med
    FROM session_rows
    WHERE ga_session_id IS NOT NULL
),
channel_groups AS (
    SELECT
        CASE
            WHEN src = '(direct)' AND med IN ('(not set)','(none)')                              THEN 'Direct'
            WHEN med IN ('display','banner','expandable','interstitial','cpm')                   THEN 'Display'
            WHEN med = 'affiliate'                                                               THEN 'Affiliates'
            WHEN med = 'referral'                                                                THEN 'Referral'
            WHEN med LIKE '%email%' OR src LIKE '%email%'                                        THEN 'Email'
            WHEN med = 'audio' OR src = 'audio'                                                  THEN 'Audio'
            WHEN med = 'sms' OR src = 'sms'                                                      THEN 'SMS'
            WHEN RIGHT(med,4) = 'push'
                 OR med LIKE '%mobile%'
                 OR med LIKE '%notification%'                                                    THEN 'Mobile Push Notifications'
            WHEN REGEXP_CONTAINS(src,r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
                 AND REGEXP_CONTAINS(med,r'(cp|ppc|retargeting|paid)')                            THEN 'Paid Shopping'
            WHEN REGEXP_CONTAINS(src,r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                 AND REGEXP_CONTAINS(med,r'(cp|ppc|paid)')                                        THEN 'Paid Search'
            WHEN REGEXP_CONTAINS(src,r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                 AND REGEXP_CONTAINS(med,r'(cp|ppc|retargeting|paid)')                            THEN 'Paid Social'
            WHEN REGEXP_CONTAINS(src,r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
                 AND REGEXP_CONTAINS(med,r'(cp|ppc|retargeting|paid)')                            THEN 'Paid Video'
            WHEN REGEXP_CONTAINS(src,r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)') THEN 'Organic Shopping'
            WHEN REGEXP_CONTAINS(src,r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                 OR med IN ('social','social-network','social-media','sm','social network','social media') THEN 'Organic Social'
            WHEN REGEXP_CONTAINS(src,r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
                 OR REGEXP_CONTAINS(med,r'video')                                                THEN 'Organic Video'
            WHEN REGEXP_CONTAINS(src,r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                 OR med = 'organic'                                                              THEN 'Organic Search'
            WHEN med = 'cross-network'
                 OR REGEXP_CONTAINS(src,r'cross-network')                                        THEN 'Cross-network'
            ELSE 'Unassigned'
        END AS channel
    FROM sessions
),
channel_stats AS (
    SELECT channel, COUNT(*) AS total_sessions
    FROM channel_groups
    GROUP BY channel
),
ranked AS (
    SELECT channel,
           total_sessions,
           DENSE_RANK() OVER (ORDER BY total_sessions DESC) AS rank
    FROM channel_stats
)
SELECT CAST(rank AS INT64) AS rank,
       channel,
       total_sessions
FROM ranked
WHERE rank = 4;