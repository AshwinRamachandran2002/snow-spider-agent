/*  December-2020 traffic – return the Channel Group that ranks 4-th
    together with its session count and its 20 biggest (source,medium) pairs */
WITH raw AS (                                   -- pull ga_session_id / source / medium from every Dec event
  SELECT
    (SELECT CAST(ep.value.int_value AS STRING)
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id'
       LIMIT 1)                                                     AS session_id,
    LOWER(COALESCE(                                                  -- source (lower-cased, blank if NULL)
      (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
         WHERE ep.key = 'source'
           AND ep.value.string_value IS NOT NULL
         LIMIT 1), ''))                                             AS source,
    LOWER(COALESCE(                                                  -- medium (lower-cased, blank if NULL)
      (SELECT ep.value.string_value
         FROM UNNEST(event_params) ep
         WHERE ep.key = 'medium'
           AND ep.value.string_value IS NOT NULL
         LIMIT 1), ''))                                             AS medium
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
),
sessions AS (                                -- one row per GA4 session
  SELECT
    session_id,
    ARRAY_AGG(source IGNORE NULLS LIMIT 1)[OFFSET(0)]  AS source,
    ARRAY_AGG(medium IGNORE NULLS LIMIT 1)[OFFSET(0)]  AS medium
  FROM raw
  WHERE session_id IS NOT NULL
  GROUP BY session_id
),
classified AS (                              -- map each session to a Channel Group
  SELECT
    session_id,
    source,
    medium,
    CASE
      WHEN source = '(direct)' AND medium IN ('(not set)', '(none)', '')          THEN 'Direct'
      WHEN medium = 'referral'                                                   THEN 'Referral'
      WHEN medium = 'organic'                                                    THEN 'Organic Search'
      WHEN medium IN ('cpc','ppc')                                               THEN 'Paid Search'
      WHEN medium IN ('display','banner','expandable','interstitial','cpm')      THEN 'Display'
      ELSE 'Unassigned'
    END AS channel_group
  FROM sessions
),
channel_ranking AS (                         -- rank Channel Groups by sessions
  SELECT
    channel_group,
    COUNT(*)                                            AS total_sessions,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC)          AS channel_rank
  FROM classified
  GROUP BY channel_group
),
top_pairs AS (                              -- session counts by (source, medium)
  SELECT
    channel_group,
    source,
    medium,
    COUNT(*) AS sessions
  FROM classified
  GROUP BY channel_group, source, medium
)
SELECT
  cr.channel_rank,               -- = 4
  cr.channel_group,              -- name of the 4-th largest Channel Group
  cr.total_sessions,
  ARRAY_AGG(
        STRUCT(tp.source, tp.medium, tp.sessions)
        ORDER BY tp.sessions DESC
        LIMIT 20
  ) AS top_source_medium_pairs
FROM channel_ranking cr
LEFT JOIN top_pairs tp
  ON tp.channel_group = cr.channel_group
WHERE cr.channel_rank = 4
GROUP BY cr.channel_rank, cr.channel_group, cr.total_sessions;