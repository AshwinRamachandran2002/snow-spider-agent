WITH sessions AS (
  -- one row per session_start event in Dec‑2020
  SELECT
    PARSE_DATE('%Y%m%d', event_date)                   AS event_date,
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id'
      LIMIT 1)                                         AS ga_session_id,
    LOWER(COALESCE(        -- session‑level source / medium / campaign
        (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'source'   LIMIT 1),
        traffic_source.source,
        '(not set)'))                                  AS source,
    LOWER(COALESCE(
        (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'medium'   LIMIT 1),
        traffic_source.medium,
        '(not set)'))                                  AS medium,
    LOWER(COALESCE(
        (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'campaign' LIMIT 1),
        traffic_source.name,
        '(not set)'))                                  AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'
    AND event_name = 'session_start'
),
channel_classified AS (
  SELECT
    *,
    CASE
      WHEN source = '(direct)' AND medium IN ('(not set)','(none)')                         THEN 'Direct'
      WHEN (REGEXP_CONTAINS(source,   r'(alibaba|amazon|shopping|shopify|etsy|ebay|stripe|walmart)')
            OR  REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])(shop|shopping)'))
           AND REGEXP_CONTAINS(medium,   r'(cp|ppc|retargeting|paid)')                       THEN 'Paid Shopping'
      WHEN REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|paid)')                                     THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|retargeting|paid)')                         THEN 'Paid Social'
      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|retargeting|paid)')                         THEN 'Paid Video'
      WHEN medium IN ('display','banner','expandable','interstitial','cpm')                  THEN 'Display'
      WHEN (REGEXP_CONTAINS(source,   r'(alibaba|amazon|shopping|shopify|etsy|ebay|stripe|walmart)')
            OR  REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])(shop|shopping)'))                  THEN 'Organic Shopping'
      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR medium IN ('social','social-network','social-media','sm',
                          'social network','social media')                                   THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(medium, r'video')                                              THEN 'Organic Video'
      WHEN REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR medium = 'organic'                                                             THEN 'Organic Search'
      WHEN medium = 'referral'                                                               THEN 'Referral'
      WHEN source IN ('email','e-mail','e_mail','e mail')
        OR medium IN ('email','e-mail','e_mail','e mail')                                    THEN 'Email'
      WHEN medium = 'affiliate'                                                              THEN 'Affiliates'
      WHEN medium = 'audio'                                                                  THEN 'Audio'
      WHEN source = 'sms' OR medium = 'sms'                                                  THEN 'SMS'
      WHEN RIGHT(medium,4) = 'push'
        OR REGEXP_CONTAINS(medium, r'(mobile|notification)')                                 THEN 'Mobile Push Notifications'
      ELSE 'Unassigned'
    END AS channel
  FROM sessions
),
channel_totals AS (
  SELECT
    channel,
    COUNT(*) AS sessions
  FROM channel_classified
  GROUP BY channel
),
ranked AS (
  SELECT
    channel,
    sessions,
    DENSE_RANK() OVER (ORDER BY sessions DESC) AS channel_rank
  FROM channel_totals
)
-- return the channel with the 4‑th largest session count
SELECT *
FROM ranked
WHERE channel_rank = 4;