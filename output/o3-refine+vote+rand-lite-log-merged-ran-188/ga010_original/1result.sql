/*  Overview of December‑2020 traffic by channel
    and identification of the channel that ranks 4th
    in number of sessions                                           */

WITH dec_events AS (
  SELECT
    user_pseudo_id,
    /* extract session id that GA4 stores in event_params            */
    ( SELECT value.int_value
      FROM   UNNEST(event_params)
      WHERE  key = 'ga_session_id'
      LIMIT  1 )                       AS ga_session_id,
    LOWER(traffic_source.source)  AS source,
    LOWER(traffic_source.medium)  AS medium,
    LOWER(traffic_source.name)    AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
),

/* one row per session (user_pseudo_id + ga_session_id) -------------*/
sessions AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    ANY_VALUE(source)   AS source,
    ANY_VALUE(medium)   AS medium,
    ANY_VALUE(campaign) AS campaign
  FROM dec_events
  WHERE ga_session_id IS NOT NULL
  GROUP BY user_pseudo_id, ga_session_id
),

/* map source / medium / campaign to a channel group ----------------*/
channel_lookup AS (
  SELECT
    user_pseudo_id,
    ga_session_id,
    CASE
      /* Direct ------------------------------------------------------*/
      WHEN source = '(direct)'
           AND (medium IN ('(not set)','(none)','') OR medium IS NULL)
        THEN 'Direct'

      /* Paid Search -------------------------------------------------*/
      WHEN REGEXP_CONTAINS(medium , r'^(cp.*|ppc|paid.*)$')
           AND REGEXP_CONTAINS(source , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
        THEN 'Paid Search'

      /* Display -----------------------------------------------------*/
      WHEN medium IN ('display','banner','expandable','interstitial','cpm')
        THEN 'Display'

      /* Organic Search ---------------------------------------------*/
      WHEN medium = 'organic'
           AND REGEXP_CONTAINS(source , r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
        THEN 'Organic Search'

      /* Paid Social -------------------------------------------------*/
      WHEN REGEXP_CONTAINS(medium , r'^(cp.*|ppc|retargeting|paid.*)$')
           AND REGEXP_CONTAINS(source , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
        THEN 'Paid Social'

      /* Organic Social ---------------------------------------------*/
      WHEN medium IN ('social','social-network','social-media','sm','social network','social media')
           OR REGEXP_CONTAINS(source , r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
        THEN 'Organic Social'

      /* Referral ----------------------------------------------------*/
      WHEN medium = 'referral'
        THEN 'Referral'

      /* Email -------------------------------------------------------*/
      WHEN medium IN ('email','e-mail','e_mail','e mail')
        OR source  IN ('email','e-mail','e_mail','e mail')
        THEN 'Email'

      /* Affiliates --------------------------------------------------*/
      WHEN medium = 'affiliate'
        THEN 'Affiliates'

      /* everything else --------------------------------------------*/
      ELSE 'Unassigned'
    END AS channel
  FROM sessions
),

/* aggregate sessions by channel and rank them ----------------------*/
ranked_channels AS (
  SELECT
    channel,
    COUNT(*)                               AS sessions,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS channel_rank
  FROM channel_lookup
  GROUP BY channel
)

/* final output: full overview ordered by rank ----------------------*/
SELECT
  channel,
  sessions,
  channel_rank      -- the channel with channel_rank = 4 is the one requested
FROM ranked_channels
ORDER BY channel_rank;