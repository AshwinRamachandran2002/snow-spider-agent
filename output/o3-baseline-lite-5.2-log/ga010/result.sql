-- 4th‑largest session‑generating channel for December 2020
WITH events_dec AS (
  SELECT
    user_pseudo_id,
    -- ga_session_id is stored inside event_params
    (SELECT ep.value.int_value
     FROM UNNEST(event_params) ep
     WHERE ep.key = 'ga_session_id')              AS ga_session_id,
    LOWER(traffic_source.source)                  AS source,
    LOWER(traffic_source.medium)                  AS medium,
    LOWER(traffic_source.name)                    AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'       -- keep only December 2020 tables
),

-- each unique (user, session) pair represents one session
sessions AS (
  SELECT DISTINCT
    user_pseudo_id,
    ga_session_id,
    source,
    medium,
    campaign
  FROM events_dec
  WHERE ga_session_id IS NOT NULL
),

-- map each session to a default channel group
classified AS (
  SELECT
    *,
    CASE
      /* Direct */
      WHEN source = '(direct)'
           AND medium IN ('(not set)', '(none)')                          THEN 'Direct'

      /* Cross‑network */
      WHEN REGEXP_CONTAINS(campaign, r'cross-network')                    THEN 'Cross-network'

      /* Paid Shopping */
      WHEN (REGEXP_CONTAINS(source, r'(alibaba|amazon|shopify|etsy|ebay|stripe|walmart|google shopping)')
             OR REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])shop|shopping'))
           AND REGEXP_CONTAINS(medium,  r'(cp|ppc|retargeting|paid)')     THEN 'Paid Shopping'

      /* Paid Search */
      WHEN REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|paid)')                  THEN 'Paid Search'

      /* Paid Social */
      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|retargeting|paid)')       THEN 'Paid Social'

      /* Paid Video */
      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(medium, r'(cp|ppc|retargeting|paid)')       THEN 'Paid Video'

      /* Display */
      WHEN medium IN ('display', 'banner', 'expandable', 'interstitial', 'cpm')
                                                                       THEN 'Display'

      /* Organic Shopping */
      WHEN REGEXP_CONTAINS(source, r'(alibaba|amazon|shopify|etsy|ebay|stripe|walmart|google shopping)')
           OR REGEXP_CONTAINS(campaign, r'(^|[^a-df-z])shop|shopping')     THEN 'Organic Shopping'

      /* Organic Social */
      WHEN REGEXP_CONTAINS(source, r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR medium IN ('social', 'social-network', 'social-media', 'sm',
                         'social network', 'social media')               THEN 'Organic Social'

      /* Organic Video */
      WHEN REGEXP_CONTAINS(source, r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(medium, r'video')                           THEN 'Organic Video'

      /* Organic Search */
      WHEN REGEXP_CONTAINS(source, r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR medium = 'organic'                                          THEN 'Organic Search'

      /* Referral */
      WHEN medium = 'referral'                                            THEN 'Referral'

      /* Email */
      WHEN REGEXP_CONTAINS(source, r'^(email|e-mail|e_mail|e mail)$')
           OR REGEXP_CONTAINS(medium, r'^(email|e-mail|e_mail|e mail)$')   THEN 'Email'

      /* Affiliates */
      WHEN medium = 'affiliate'                                           THEN 'Affiliates'

      /* Audio */
      WHEN medium = 'audio'                                               THEN 'Audio'

      /* SMS */
      WHEN source = 'sms' OR medium = 'sms'                               THEN 'SMS'

      /* Mobile Push Notifications */
      WHEN REGEXP_CONTAINS(medium, r'(push$|mobile|notification)')        THEN 'Mobile Push Notifications'

      /* Anything else */
      ELSE 'Unassigned'
    END AS channel_group
  FROM sessions
),

-- count sessions per channel
channel_totals AS (
  SELECT
    channel_group,
    COUNT(*) AS session_count
  FROM classified
  GROUP BY channel_group
),

-- rank channels by sessions
ranked AS (
  SELECT
    channel_group,
    session_count,
    RANK() OVER (ORDER BY session_count DESC) AS rank_in_dec
  FROM channel_totals
)

-- return the 4th‑highest
SELECT
  channel_group  AS fourth_highest_channel,
  session_count  AS sessions_in_dec_2020
FROM ranked
WHERE rank_in_dec = 4;