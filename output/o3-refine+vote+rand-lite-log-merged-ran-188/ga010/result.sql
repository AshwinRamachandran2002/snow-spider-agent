/*  Website-traffic overview for December 2020  
    – counts distinct GA4 sessions, groups them into high-level channels,  
    – ranks the channels and flags the one in 4th place                                       */

WITH base AS (   -- one row per session id found in December event tables
  SELECT DISTINCT
    user_pseudo_id,
    sid,
    LOWER(ts.medium) AS medium,
    LOWER(ts.source) AS source
  FROM (
    SELECT
      user_pseudo_id,
      traffic_source          AS ts,
      (SELECT ep.value.int_value
         FROM UNNEST(event_params) ep
         WHERE ep.key = 'ga_session_id') AS sid            -- session id
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  )
  WHERE sid IS NOT NULL
),

agg AS (         -- map each session into a simplified channel group
  SELECT
    CASE
      WHEN source = '(direct)' AND medium IN ('(not set)', '(none)') THEN 'Direct'
      WHEN medium = 'organic'                                         THEN 'Organic Search'
      WHEN medium = 'referral'                                        THEN 'Referral'
      ELSE 'Unassigned'
    END AS channel_group,
    COUNT(DISTINCT CONCAT(user_pseudo_id,'-',CAST(sid AS STRING))) AS sessions
  FROM base
  GROUP BY channel_group
),

ranked AS (      -- rank channels by session volume
  SELECT
    channel_group,
    sessions,
    DENSE_RANK() OVER (ORDER BY sessions DESC) AS rnk
  FROM agg
)

SELECT
  channel_group,
  sessions,
  rnk,
  CASE WHEN rnk = 4 THEN '← 4th-highest channel' END AS highlight
FROM ranked
ORDER BY rnk;