/*  Overview of December-2020 traffic and the channel with the 4-th most sessions  */
WITH sessions AS (
  /* 1. one row per session (session_start only) */
  SELECT
    CONCAT(
      user_pseudo_id , '-' ,
      (SELECT value.int_value
         FROM UNNEST(event_params)
        WHERE key = 'ga_session_id')            -- numeric id stored in event_params
    )                                            AS session_key,
    LOWER(traffic_source.source)  AS src,
    LOWER(traffic_source.medium)  AS med
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
  WHERE event_name = 'session_start'
),
channels AS (
  /* 2. map each session to a Channel Group */
  SELECT
    session_key,
    CASE
        WHEN med IN ('(not set)','(none)') AND src = '(direct)'                       THEN 'Direct'
        WHEN med = 'referral'                                                        THEN 'Referral'
        WHEN med = 'email'       OR src = 'email'                                    THEN 'Email'
        WHEN med = 'affiliate'                                                       THEN 'Affiliates'
        WHEN med = 'organic'
             OR src IN ('google','bing','baidu','yahoo','duckduckgo','ecosia','yandex')
                                                                                     THEN 'Organic Search'
        ELSE 'Unassigned'
    END AS channel
  FROM sessions
),
aggregated AS (
  /* 3. count distinct sessions per channel */
  SELECT
    channel,
    COUNT(DISTINCT session_key) AS sessions
  FROM channels
  GROUP BY channel
),
ranked AS (
  /* 4. rank channels by session volume */
  SELECT
    channel,
    sessions,
    DENSE_RANK() OVER (ORDER BY sessions DESC) AS rnk
  FROM aggregated
)
SELECT
  channel   AS fourth_highest_channel,
  sessions  AS session_count
FROM ranked
WHERE rnk = 4;