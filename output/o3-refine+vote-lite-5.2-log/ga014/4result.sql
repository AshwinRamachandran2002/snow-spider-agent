/*  Total number of sessions per traffic‑channel in December‑2020  */

WITH base AS (          -- pull one row per event, extract session level fields
  SELECT
    user_pseudo_id,

    /* session id that GA4 writes in event_params               */
    ( SELECT ep.value.int_value
      FROM   UNNEST(event_params) ep
      WHERE  ep.key = 'ga_session_id'
    )                                                     AS session_id,

    /* try event‑params first, fall back on traffic_source      */
    LOWER( COALESCE(
      ( SELECT ep.value.string_value
        FROM   UNNEST(event_params) ep
        WHERE  ep.key = 'source'
      ),
      traffic_source.source,
      '(direct)')
    )                                                     AS source,

    LOWER( COALESCE(
      ( SELECT ep.value.string_value
        FROM   UNNEST(event_params) ep
        WHERE  ep.key = 'medium'
      ),
      traffic_source.medium,
      '(none)')
    )                                                     AS medium,

    LOWER( COALESCE(
      ( SELECT ep.value.string_value
        FROM   UNNEST(event_params) ep
        WHERE  ep.key = 'campaign'
      ),
      traffic_source.name,
      '')
    )                                                     AS campaign
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE
    _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'       -- December‑2020
    AND ( SELECT ep.value.int_value
          FROM   UNNEST(event_params) ep
          WHERE  ep.key = 'ga_session_id') IS NOT NULL    -- keep only events with a session id
),

sessions AS (           -- one row per session
  SELECT DISTINCT
    user_pseudo_id,
    session_id,
    source,
    medium,
    campaign
  FROM base
),

classified AS (         -- apply GA4 channel‑grouping rules
  SELECT
    *,
    CASE
      /* --- Direct ---------------------------------------------------------- */
      WHEN source = '(direct)'
           AND medium IN ('(not set)','(none)')
        THEN 'Direct'

      /* --- Paid Shopping --------------------------------------------------- */
      WHEN ( REGEXP_CONTAINS(source  , r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
             OR REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])(shop|shopping)') )
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')
        THEN 'Paid Shopping'

      /* --- Paid Search ----------------------------------------------------- */
      WHEN REGEXP_CONTAINS(source , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|paid)')
        THEN 'Paid Search'

      /* --- Paid Social ----------------------------------------------------- */
      WHEN REGEXP_CONTAINS(source , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')
        THEN 'Paid Social'

      /* --- Paid Video ------------------------------------------------------ */
      WHEN REGEXP_CONTAINS(source , r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(medium , r'(cp|ppc|retargeting|paid)')
        THEN 'Paid Video'

      /* --- Display --------------------------------------------------------- */
      WHEN medium IN ('display','banner','expandable','interstitial','cpm')
        THEN 'Display'

      /* --- Organic Shopping ------------------------------------------------ */
      WHEN   REGEXP_CONTAINS(source  , r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
          OR REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])(shop|shopping)')
        THEN 'Organic Shopping'

      /* --- Organic Social -------------------------------------------------- */
      WHEN   REGEXP_CONTAINS(source , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
          OR medium IN ('social','social-network','social-media','sm','social network','social media')
        THEN 'Organic Social'

      /* --- Organic Video --------------------------------------------------- */
      WHEN   REGEXP_CONTAINS(source , r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
          OR REGEXP_CONTAINS(medium , r'video')
        THEN 'Organic Video'

      /* --- Organic Search -------------------------------------------------- */
      WHEN   REGEXP_CONTAINS(source , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
          OR medium = 'organic'
        THEN 'Organic Search'

      /* --- Referral -------------------------------------------------------- */
      WHEN medium = 'referral'
        THEN 'Referral'

      /* --- Email ----------------------------------------------------------- */
      WHEN source IN ('email','e-mail','e_mail','e mail')
        OR  medium IN ('email','e-mail','e_mail','e mail')
        THEN 'Email'

      /* --- Affiliates ------------------------------------------------------ */
      WHEN medium = 'affiliate'
        THEN 'Affiliates'

      /* --- Audio ----------------------------------------------------------- */
      WHEN medium = 'audio'
        THEN 'Audio'

      /* --- SMS ------------------------------------------------------------- */
      WHEN source = 'sms' OR medium = 'sms'
        THEN 'SMS'

      /* --- Mobile Push Notifications -------------------------------------- */
      WHEN REGEXP_CONTAINS(medium , r'(push)')
        OR REGEXP_CONTAINS(medium , r'(mobile|notification)')
        THEN 'Mobile Push Notifications'

      /* --- Cross‑network --------------------------------------------------- */
      WHEN REGEXP_CONTAINS(campaign, 'cross-network')
        THEN 'Cross-network'

      /* --- Unassigned ------------------------------------------------------ */
      ELSE 'Unassigned'
    END AS channel_group
  FROM sessions
)

SELECT
  channel_group   AS traffic_channel,
  COUNT(*)        AS total_sessions
FROM  classified
GROUP BY traffic_channel
ORDER BY total_sessions DESC;