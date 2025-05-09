-- 4th‑largest traffic channel (by sessions) for December 2020
WITH sessions AS (
  -- each session is represented by its single `session_start` event
  SELECT
    DATE(PARSE_DATE('%Y%m%d', event_date))                  AS session_date,
    user_pseudo_id,
    (SELECT value.int_value   FROM UNNEST(event_params) WHERE key = 'ga_session_id' LIMIT 1) AS ga_session_id,
    COALESCE(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'source'  LIMIT 1),
      traffic_source.source
    ) AS source,
    COALESCE(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'medium'  LIMIT 1),
      traffic_source.medium
    ) AS medium,
    COALESCE(
      (SELECT value.string_value FROM UNNEST(event_params) WHERE key = 'campaign' LIMIT 1),
      traffic_source.name
    ) AS campaign
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
),

channel_sessions AS (
  SELECT
    -- simplified default‑channel grouping
    CASE
      WHEN LOWER(source) = '(direct)' AND LOWER(medium) IN ('(not set)', '(none)', '')            THEN 'Direct'
      WHEN LOWER(medium) IN ('display','banner','expandable','interstitial','cpm')                THEN 'Display'
      WHEN LOWER(medium) = 'affiliate'                                                           THEN 'Affiliates'
      WHEN LOWER(medium) = 'referral'                                                            THEN 'Referral'
      WHEN LOWER(medium) = 'email' OR REGEXP_CONTAINS(LOWER(source), r'(email|e-mail|e_mail)')    THEN 'Email'
      WHEN LOWER(medium) = 'audio'                                                               THEN 'Audio'
      WHEN LOWER(medium) = 'sms'   OR LOWER(source) = 'sms'                                      THEN 'SMS'
      WHEN REGEXP_CONTAINS(LOWER(source), r'(baidu|bing|duckduckgo|ecosia|google|yahoo|yandex)')
           AND LOWER(medium) = 'organic'                                                         THEN 'Organic Search'
      WHEN REGEXP_CONTAINS(LOWER(source), r'(facebook|instagram|linkedin|pinterest|tiktok|twitter|whatsapp|badoo|fb)')
           OR LOWER(medium) IN ('social','social-network','social-media','sm','social network','social media')
                                                                                                 THEN 'Organic Social'
      ELSE 'Unassigned'
    END                                                   AS channel_group,
    COUNT(*)                                              AS sessions
  FROM sessions
  GROUP BY channel_group
)

SELECT channel_group,
       sessions
FROM channel_sessions
ORDER BY sessions DESC                  -- rank channels by number of sessions
LIMIT 1 OFFSET 3;                        -- 4th highest (skip first 3)