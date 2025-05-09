-- Overview of December-2020 traffic by channel group
-- (row with session_rank = 4 is the channel that had the 4th-highest number of sessions)
WITH event_data AS (
  SELECT
    CASE
      WHEN LOWER(traffic_source.source) = '(direct)'
           AND LOWER(traffic_source.medium) IN ('(not set)', '(none)')                       THEN 'Direct'
      WHEN LOWER(traffic_source.medium) = 'referral'                                         THEN 'Referral'
      WHEN LOWER(traffic_source.medium) = 'organic'                                          THEN 'Organic Search'
      WHEN LOWER(traffic_source.medium) IN ('email','e-mail','e_mail','e mail')              THEN 'Email'
      WHEN LOWER(traffic_source.medium) IN ('display','banner','expandable','interstitial','cpm')
                                                                                            THEN 'Display'
      ELSE 'Unassigned'
    END                                   AS channel_group,
    event_name
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
),
session_totals AS (
  SELECT
    channel_group,
    COUNTIF(event_name = 'session_start') AS sessions
  FROM event_data
  GROUP BY channel_group
),
ranked_channels AS (
  SELECT
    channel_group,
    sessions,
    RANK() OVER (ORDER BY sessions DESC)                           AS session_rank,
    ROUND(100 * sessions / SUM(sessions) OVER (), 2)               AS pct_of_total_sessions
  FROM session_totals
)
SELECT
  channel_group,
  sessions,
  pct_of_total_sessions,
  session_rank
FROM ranked_channels
ORDER BY session_rank;