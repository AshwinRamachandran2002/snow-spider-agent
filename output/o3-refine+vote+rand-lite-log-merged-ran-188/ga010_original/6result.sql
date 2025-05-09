/*  December‑2020 traffic overview + channel with 4th‑most sessions  */
WITH dec20_session_start AS (           -- 1. take every session_start in Dec‑2020
  SELECT
    CONCAT(user_pseudo_id,'-',           -- a session = unique (user, ga_session_id)
           CAST((
             SELECT ep.value.int_value
             FROM UNNEST(event_params) ep
             WHERE ep.key = 'ga_session_id'
           ) AS STRING))                    AS session_id,
    LOWER(traffic_source.source)            AS src ,
    LOWER(traffic_source.medium)            AS med
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
),

classified AS (                          -- 2. map every session to a Channel Group
  SELECT
    session_id,
    CASE
      /* Direct */
      WHEN src = '(direct)' AND med IN ('(not set)','(none)')                       THEN 'Direct'
      /* Paid channels */
      WHEN REGEXP_CONTAINS(src ,r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND REGEXP_CONTAINS(med ,r'(cp|ppc|paid)')                               THEN 'Paid Search'
      WHEN REGEXP_CONTAINS(src ,r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
           AND REGEXP_CONTAINS(med ,r'(cp|ppc|retargeting|paid)')                   THEN 'Paid Shopping'
      WHEN REGEXP_CONTAINS(src ,r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           AND REGEXP_CONTAINS(med ,r'(cp|ppc|retargeting|paid)')                   THEN 'Paid Social'
      /* Display */
      WHEN med IN ('display','banner','expandable','interstitial','cpm')            THEN 'Display'
      /* Organic channels */
      WHEN REGEXP_CONTAINS(src ,r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           OR med = 'organic'                                                      THEN 'Organic Search'
      WHEN REGEXP_CONTAINS(src ,r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
           OR med IN ('social','social-network','social-media','sm','social network','social media')
                                                                                        THEN 'Organic Social'
      WHEN REGEXP_CONTAINS(src ,r'(alibaba|amazon|google shopping|shopify|etsy|ebay|stripe|walmart)')
                                                                                        THEN 'Organic Shopping'
      /* Referral */
      WHEN med = 'referral'                                                        THEN 'Referral'
      /* catch‑all */
      ELSE 'Unassigned'
    END AS channel_group
  FROM dec20_session_start
),

sessions_by_channel AS (                 -- 3. count distinct sessions per channel
  SELECT
    channel_group,
    COUNT(DISTINCT session_id) AS sessions
  FROM classified
  GROUP BY channel_group
),

ranked AS (                              -- 4. rank channels by sessions
  SELECT
    channel_group,
    sessions,
    DENSE_RANK() OVER(ORDER BY sessions DESC) AS channel_rank
  FROM sessions_by_channel
)

SELECT channel_group,
       sessions,
       channel_rank
FROM ranked
ORDER BY sessions DESC;