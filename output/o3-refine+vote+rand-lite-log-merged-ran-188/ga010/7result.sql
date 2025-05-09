-- December-2020 website traffic by channel and the corresponding rank
WITH channel_sessions AS (
  SELECT
    -- Basic channel grouping logic
    CASE
      WHEN LOWER(traffic_source.source) = '(direct)'
           AND LOWER(traffic_source.medium) IN ('(not set)', '(none)')                 THEN 'Direct'
      WHEN LOWER(traffic_source.medium) = 'affiliate'                                 THEN 'Affiliates'
      WHEN LOWER(traffic_source.medium) = 'referral'                                  THEN 'Referral'
      WHEN LOWER(traffic_source.medium) IN ('display','banner','expandable',
                                            'interstitial','cpm')                     THEN 'Display'
      WHEN REGEXP_CONTAINS(LOWER(traffic_source.medium), r'email')
        OR REGEXP_CONTAINS(LOWER(traffic_source.source), r'email')                    THEN 'Email'
      WHEN LOWER(traffic_source.medium) = 'organic'
        OR LOWER(traffic_source.source) IN ('google','bing','yahoo','baidu',
                                            'duckduckgo','yandex','ecosia')           THEN 'Organic Search'
      ELSE 'Other'
    END                                            AS channel,
    COUNT(*)                                       AS sessions
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201201' AND '20201231'   -- December 2020
    AND event_name = 'session_start'                      -- one row per session
  GROUP BY channel
),
ranked_channels AS (
  SELECT
    channel,
    sessions,
    RANK() OVER (ORDER BY sessions DESC) AS channel_rank
  FROM channel_sessions
)
SELECT
  channel,
  sessions,
  channel_rank
FROM ranked_channels
ORDER BY channel_rank;   -- the row with channel_rank = 4 is the requested one