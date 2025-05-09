/*  Channel with the 4‑th highest number of sessions in December‑2020  */
WITH dec_events AS (      -- explicit UNION of every existing 2020‑12 GA4 table
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

/*  Extract one row per session_start hit and pull in source / medium        */
/*  – first from event_params, otherwise from traffic_source.*               */
sessions AS (
  SELECT
    CONCAT(
      user_pseudo_id, '-', 
      CAST(
        (SELECT value.int_value
         FROM UNNEST(event_params)
         WHERE key = 'ga_session_id') AS STRING
      )
    )                                                            AS session_id,
    LOWER(
      COALESCE(
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source'),
        traffic_source.source
      )
    )                                                            AS src,
    LOWER(
      COALESCE(
        (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium'),
        traffic_source.medium
      )
    )                                                            AS med
  FROM dec_events
  WHERE event_name = 'session_start'
),

/*  Map every session to a Google‑style default channel group                */
classified AS (
  SELECT
    session_id,
    CASE
      WHEN src = '(direct)' AND med IN ('(not set)','(none)',NULL)                         THEN 'Direct'
      WHEN med = 'affiliate'                                                               THEN 'Affiliates'
      WHEN med IN ('display','banner','expandable','interstitial','cpm')                   THEN 'Display'
      WHEN med = 'referral'                                                                THEN 'Referral'
      WHEN med = 'audio'                                                                   THEN 'Audio'
      WHEN src = 'sms' OR med = 'sms'                                                      THEN 'SMS'
      WHEN med LIKE '%push' OR med LIKE '%mobile%' OR med LIKE '%notification%'            THEN 'Mobile Push Notifications'
      WHEN REGEXP_CONTAINS(src, '(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND med NOT LIKE '%paid%' AND med NOT LIKE '%cp%' AND med NOT LIKE '%ppc%'       THEN 'Organic Search'
      WHEN REGEXP_CONTAINS(src, '(alibaba|amazon|google[ ]shopping|shopify|etsy|ebay|stripe|walmart)')
           AND med NOT LIKE '%paid%' AND med NOT LIKE '%cp%' AND med NOT LIKE '%ppc%'       THEN 'Organic Shopping'
      WHEN (REGEXP_CONTAINS(src, '(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
             OR med IN ('social','social-network','social-media','sm','social network','social media'))
           AND med NOT LIKE '%paid%' AND med NOT LIKE '%cp%' AND med NOT LIKE '%ppc%'       THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(src, '(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND med NOT LIKE '%paid%' AND med NOT LIKE '%cp%' AND med NOT LIKE '%ppc%'       THEN 'Organic Video'
      WHEN med LIKE '%email%' OR src LIKE '%email%'                                        THEN 'Email'
      WHEN REGEXP_CONTAINS(src, '(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND (med LIKE '%paid%' OR med LIKE '%cp%' OR med LIKE '%ppc%')                   THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(src, '(alibaba|amazon|google[ ]shopping|shopify|etsy|ebay|stripe|walmart)')
           AND (med LIKE '%paid%' OR med LIKE '%cp%' OR med LIKE '%ppc%')                   THEN 'Paid Shopping'
      WHEN REGEXP_CONTAINS(src, '(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND (med LIKE '%paid%' OR med LIKE '%cp%' OR med LIKE '%ppc%' OR med LIKE '%retargeting%')
                                                                                           THEN 'Paid Social'
      WHEN REGEXP_CONTAINS(src, '(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND (med LIKE '%paid%' OR med LIKE '%cp%' OR med LIKE '%ppc%' OR med LIKE '%retargeting%')
                                                                                           THEN 'Paid Video'
      ELSE 'Unassigned'
    END AS channel
  FROM sessions
),

/*  Aggregate sessions per channel and rank them                            */
ranked AS (
  SELECT
    channel,
    COUNT(DISTINCT session_id) AS total_sessions,
    DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT session_id) DESC) AS rank
  FROM classified
  GROUP BY channel
)

/*  Return the 4‑th ranked channel                                           */
SELECT
  CAST(rank AS INT64) AS rank,
  channel,
  total_sessions
FROM ranked
WHERE rank = 4;