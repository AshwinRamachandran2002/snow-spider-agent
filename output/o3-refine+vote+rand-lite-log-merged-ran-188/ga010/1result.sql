-- Sessions by channel for December-2020  +  rank to spot the 4th-largest one
WITH session_events AS (
  -- 1. pick every session_start event and pull its session_id
  SELECT
    user_pseudo_id,
    (SELECT ep.value.int_value
       FROM UNNEST(event_params) AS ep
      WHERE ep.key = 'ga_session_id'
      LIMIT 1)                       AS session_id,
    traffic_source
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE
    event_name = 'session_start'
),
session_channels AS (
  -- 2. map Source / Medium onto a simplified GA4 default channel group
  SELECT
    CASE
        WHEN LOWER(traffic_source.source) = '(direct)'
             AND (traffic_source.medium IS NULL
                  OR traffic_source.medium IN ('(not set)', '(none)'))         THEN 'Direct'
        WHEN LOWER(traffic_source.medium) = 'organic'                          THEN 'Organic Search'
        WHEN LOWER(traffic_source.medium) = 'referral'                         THEN 'Referral'
        WHEN LOWER(traffic_source.medium) IN ('display','banner','expandable',
                                              'interstitial','cpm')            THEN 'Display'
        WHEN REGEXP_CONTAINS(LOWER(traffic_source.medium), r'cpc|ppc|paid')    THEN 'Paid Search'
        ELSE 'Unassigned'
    END                                                AS channel_group,
    CONCAT(user_pseudo_id,'-',CAST(session_id AS STRING)) AS session_key
  FROM
    session_events
)
-- 3. aggregate & rank; the row with channel_rank = 4 is the one requested
SELECT
  channel_group,
  COUNT(DISTINCT session_key)                        AS sessions,
  DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT session_key) DESC) AS channel_rank
FROM
  session_channels
GROUP BY
  channel_group
ORDER BY
  channel_rank;