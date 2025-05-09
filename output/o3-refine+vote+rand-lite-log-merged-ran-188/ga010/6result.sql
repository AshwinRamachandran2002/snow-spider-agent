/*  Overview of December-2020 traffic by channel and the channel that ranks 4th  */

WITH cleaned AS (
  /* pull source / medium + session id for every December-2020 session_start */
  SELECT
    LOWER(traffic_source.source)  AS src,
    LOWER(traffic_source.medium)  AS med,
    user_pseudo_id,
    ep.value.int_value            AS ga_session_id
  FROM
    `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`,
    UNNEST(event_params) AS ep
  WHERE
    event_name = 'session_start'
    AND ep.key = 'ga_session_id'
),
session_channels AS (
  /* apply GA-like channel rules */
  SELECT
    CASE
      WHEN src = '(direct)' AND med IN ('(not set)', '(none)')                     THEN 'Direct'
      WHEN med = 'affiliate'                                                      THEN 'Affiliates'
      WHEN med IN ('display','banner','cpm','expandable','interstitial')          THEN 'Display'
      WHEN med = 'email' OR src = 'email'                                         THEN 'Email'
      WHEN med = 'organic'
           OR src IN ('google','bing','yahoo','duckduckgo','baidu')               THEN 'Organic Search'
      WHEN med = 'referral'                                                       THEN 'Referral'
      ELSE 'Unassigned'
    END                                                         AS channel,
    CONCAT(user_pseudo_id,'|',CAST(ga_session_id AS STRING))    AS session_id
  FROM cleaned
),
channel_ranking AS (
  /* count sessions per channel and rank them */
  SELECT
    channel,
    COUNT(DISTINCT session_id)                              AS sessions,
    ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT session_id) DESC) AS rn
  FROM session_channels
  GROUP BY channel
)

SELECT
  channel,
  sessions,
  rn
FROM channel_ranking
ORDER BY rn;