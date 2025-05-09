/*  Total number of GA4 sessions per traffic‑channel for December‑2020  */

WITH dec_events AS (
  -- pull only December‑2020 events
  SELECT
    user_pseudo_id,

    /* grab the session id that GA4 stores in event_params */
    ( SELECT ep.value.int_value
      FROM UNNEST(event_params) ep
      WHERE ep.key = 'ga_session_id' )                      AS session_id,

    LOWER( ( SELECT ep.value.string_value
             FROM UNNEST(event_params) ep
             WHERE ep.key = 'source'   ) )                  AS source,

    LOWER( ( SELECT ep.value.string_value
             FROM UNNEST(event_params) ep
             WHERE ep.key = 'medium'   ) )                  AS medium,

    LOWER( ( SELECT ep.value.string_value
             FROM UNNEST(event_params) ep
             WHERE ep.key = 'campaign' ) )                  AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
),

/* one row = one GA4 session */
sessions AS (
  SELECT
    user_pseudo_id,
    session_id,
    ANY_VALUE(source)   AS source,
    ANY_VALUE(medium)   AS medium,
    ANY_VALUE(campaign) AS campaign
  FROM dec_events
  WHERE session_id IS NOT NULL
  GROUP BY user_pseudo_id, session_id
),

/* apply Channel‑grouping rules */
classified AS (
  SELECT
    *,
    CASE
      /* Direct --------------------------------------------------------*/
      WHEN source = '(direct)'
           AND COALESCE(medium,'') IN ('', '(none)', '(not set)')              THEN 'Direct'

      /* Cross‑network -------------------------------------------------*/
      WHEN REGEXP_CONTAINS(COALESCE(campaign,''), r'cross-network')            THEN 'Cross-network'

      /* Paid channels -------------------------------------------------*/
      WHEN REGEXP_CONTAINS(COALESCE(source,''), r'(alibaba|amazon|google ?shopping|shopify|etsy|ebay|stripe|walmart)')
           AND REGEXP_CONTAINS(COALESCE(medium,''), r'(cp.*|ppc|retargeting|paid.*)')   THEN 'Paid Shopping'

      WHEN REGEXP_CONTAINS(COALESCE(source,''), r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(COALESCE(medium,''), r'(cp.*|ppc|paid.*)')               THEN 'Paid Search'

      WHEN REGEXP_CONTAINS(COALESCE(source,''), r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(COALESCE(medium,''), r'(cp.*|ppc|retargeting|paid.*)')   THEN 'Paid Social'

      WHEN REGEXP_CONTAINS(COALESCE(source,''), r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           AND REGEXP_CONTAINS(COALESCE(medium,''), r'(cp.*|ppc|retargeting|paid.*)')   THEN 'Paid Video'

      /* Display -------------------------------------------------------*/
      WHEN medium IN ('display','banner','expandable','interstitial','cpm')    THEN 'Display'

      /* Organic channels ---------------------------------------------*/
      WHEN REGEXP_CONTAINS(COALESCE(source,''), r'(alibaba|amazon|google ?shopping|shopify|etsy|ebay|stripe|walmart)')
           OR REGEXP_CONTAINS(COALESCE(campaign,''), r'(^.*(([^a-df-z]|^)shop|shopping).*$)')     THEN 'Organic Shopping'

      WHEN REGEXP_CONTAINS(COALESCE(source,''), r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR medium IN ('social','social-network','social-media','sm','social network','social media')
                                                                                THEN 'Organic Social'

      WHEN REGEXP_CONTAINS(COALESCE(source,''), r'(dailymotion|disneyplus|netflix|youtube|vimeo|twitch)')
           OR REGEXP_CONTAINS(COALESCE(medium,''), r'video')                    THEN 'Organic Video'

      WHEN REGEXP_CONTAINS(COALESCE(source,''), r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR medium = 'organic'                                               THEN 'Organic Search'

      /* Other predefined channels ------------------------------------*/
      WHEN medium = 'referral'                                                THEN 'Referral'
      WHEN REGEXP_CONTAINS(COALESCE(source,''), r'email|e[-_ ]?mail')
           OR REGEXP_CONTAINS(COALESCE(medium,''), r'email|e[-_ ]?mail')        THEN 'Email'
      WHEN medium = 'affiliate'                                               THEN 'Affiliates'
      WHEN medium = 'audio'                                                   THEN 'Audio'
      WHEN medium = 'sms'  OR source = 'sms'                                  THEN 'SMS'
      WHEN REGEXP_CONTAINS(COALESCE(medium,''), r'push')
           OR REGEXP_CONTAINS(COALESCE(medium,''), r'mobile|notification')      THEN 'Mobile Push Notifications'

      /* Fallback ------------------------------------------------------*/
      ELSE 'Unassigned'
    END AS channel
  FROM sessions
)

/* final result ----------------------------------------------------------*/
SELECT
  channel,
  COUNT(*) AS total_sessions
FROM classified
GROUP BY channel
ORDER BY total_sessions DESC;