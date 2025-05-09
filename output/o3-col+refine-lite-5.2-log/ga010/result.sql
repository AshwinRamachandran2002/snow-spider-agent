-- Overview of December‑2020 traffic channels
-- and return the channel with the 4‑th highest number of sessions
WITH sessions_per_event AS (
  SELECT
    -- 1. Map source / medium to a simplified channel name
    CASE
      WHEN traffic_source.source = '(direct)'
           AND traffic_source.medium IN ('(not set)', '(none)', '')         THEN 'Direct'
      WHEN LOWER(traffic_source.medium) = 'referral'                        THEN 'Referral'
      WHEN LOWER(traffic_source.medium) = 'organic'                         THEN 'Organic Search'
      WHEN REGEXP_CONTAINS(LOWER(traffic_source.medium), r'(cpc|ppc|paid)') THEN 'Paid Search'
      WHEN LOWER(traffic_source.medium) IN ('social','social-network',
                                            'social-media','sm',
                                            'social network','social media')
           OR REGEXP_CONTAINS(LOWER(traffic_source.source),
                              r'(badoo|facebook|fb|instagram|linkedin|pinterest|tiktok|twitter|whatsapp)')
                                                                            THEN 'Organic Social'
      ELSE 'Unassigned'
    END                                                              AS channel,

    -- 2. Build a unique session key: user_pseudo_id + ga_session_id
    CONCAT(
      user_pseudo_id,
      '-',
      (SELECT value.int_value
         FROM UNNEST(event_params)
         WHERE key = 'ga_session_id'
         LIMIT 1)
    )                                                                 AS session_key
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'   -- December 2020 tables
    AND event_name = 'session_start'                      -- one row per session
),

-- 3. Count distinct sessions per channel
channel_sessions AS (
  SELECT
    channel,
    COUNT(DISTINCT session_key) AS sessions
  FROM sessions_per_event
  GROUP BY channel
)

-- 4. Return the channel that ranks 4‑th by session count
SELECT
  channel,
  sessions
FROM channel_sessions
QUALIFY ROW_NUMBER() OVER (ORDER BY sessions DESC) = 4;