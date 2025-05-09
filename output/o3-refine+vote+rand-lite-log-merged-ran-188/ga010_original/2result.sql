/* 4‑th largest session channel in December 2020 */

WITH events_dec AS (       -- every event of Dec‑2020, pull session‑level fields
  SELECT
    user_pseudo_id,
    ( SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id')                            AS ga_session_id,

    LOWER( COALESCE(
      ( SELECT ep.value.string_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'source')
    ,''))                                                        AS source,

    LOWER( COALESCE(
      ( SELECT ep.value.string_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'medium')
    ,''))                                                        AS medium,

    LOWER( COALESCE(
      ( SELECT ep.value.string_value
        FROM UNNEST(event_params) ep
        WHERE ep.key = 'campaign')
    ,''))                                                        AS campaign_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'          -- December 2020
),

sessions AS (                -- one row per distinct session
  SELECT DISTINCT
    user_pseudo_id,
    ga_session_id,
    source,
    medium,
    campaign_name
  FROM events_dec
  WHERE ga_session_id IS NOT NULL
),

classified AS (              -- map each session to a channel
  SELECT
    *,
    CASE
      WHEN source = '(direct)'
           AND medium IN ('', '(not set)', '(none)')                              THEN 'Direct'
      WHEN REGEXP_CONTAINS(campaign_name, r'cross-network')                        THEN 'Cross-network'
      WHEN (REGEXP_CONTAINS(source, r'(alibaba|amazon|googleshopping|shopify|etsy|ebay|stripe|walmart)')
            OR REGEXP_CONTAINS(campaign_name, r'(^|[^a-df-z])shop|shopping'))
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|retargeting|paid)')               THEN 'Paid Shopping'
      WHEN REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|cpc|paid)')                       THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|retargeting|paid)')               THEN 'Paid Social'
      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|retargeting|paid)')               THEN 'Paid Video'
      WHEN medium IN ('display','banner','expandable','interstitial','cpm')        THEN 'Display'
      WHEN (REGEXP_CONTAINS(source, r'(alibaba|amazon|googleshopping|shopify|etsy|ebay|stripe|walmart)')
            OR REGEXP_CONTAINS(campaign_name, r'(^|[^a-df-z])shop|shopping'))
           AND medium NOT LIKE '%paid%'                                           THEN 'Organic Shopping'
      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR medium IN ('social','social-network','social-media','sm',
                          'social network','social media')                         THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(medium, r'video')                                    THEN 'Organic Video'
      WHEN medium = 'organic'
           OR REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
                                                                                   THEN 'Organic Search'
      WHEN medium = 'referral'                                                    THEN 'Referral'
      WHEN source IN ('email','e-mail','e_mail','e mail')
           OR medium IN ('email','e-mail','e_mail','e mail')                       THEN 'Email'
      WHEN medium = 'affiliate'                                                   THEN 'Affiliates'
      WHEN medium = 'audio'                                                       THEN 'Audio'
      WHEN source = 'sms' OR medium = 'sms'                                       THEN 'SMS'
      WHEN REGEXP_CONTAINS(medium, r'(mobile|notification)')
           OR REGEXP_CONTAINS(medium, r'push$')                                    THEN 'Mobile Push Notifications'
      ELSE 'Unassigned'
    END AS channel
  FROM sessions
),

agg AS (                      -- session counts by channel
  SELECT
    channel,
    COUNT(*) AS session_cnt
  FROM classified
  GROUP BY channel
),

ranked AS (                   -- rank channels
  SELECT
    channel,
    session_cnt,
    ROW_NUMBER() OVER (ORDER BY session_cnt DESC, channel) AS rn
  FROM agg
)

SELECT
  channel       AS fourth_highest_channel,
  session_cnt   AS sessions_in_dec_2020
FROM ranked
WHERE rn = 4;