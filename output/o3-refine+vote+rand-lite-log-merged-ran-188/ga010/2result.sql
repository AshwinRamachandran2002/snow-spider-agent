/*  Overview of December-2020 traffic and the channel that ranks 4th in sessions  */

WITH base AS (
  SELECT
    event_date,
    user_pseudo_id,
    (SELECT ep.value.int_value                     -- GA4 session id
       FROM UNNEST(event_params) ep
       WHERE ep.key = 'ga_session_id') AS ga_session_id,
    traffic_source.source  AS source,
    traffic_source.medium  AS medium
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
),

/* One row per session-hit */
sessions AS (
  SELECT
    event_date,
    CONCAT(user_pseudo_id, '-', ga_session_id)     AS session_key,
    CASE
      WHEN LOWER(medium) IN ('(not set)', '(none)') AND source = '(direct)' THEN 'Direct'
      WHEN LOWER(medium) = 'organic'                                                  THEN 'Organic Search'
      WHEN LOWER(medium) = 'referral'                                                 THEN 'Referral'
      ELSE                                                                              'Other'
    END AS channel
  FROM base
  WHERE ga_session_id IS NOT NULL                         -- keep only rows where we know the session
),

/* Total sessions by channel (December 2020) */
channel_totals AS (
  SELECT
    channel,
    COUNT(DISTINCT session_key) AS sessions
  FROM sessions
  GROUP BY channel
),

/* Rank channels by session volume */
ranked AS (
  SELECT
    channel,
    sessions,
    ROW_NUMBER() OVER (ORDER BY sessions DESC) AS rn
  FROM channel_totals
)

/* ---------------------------------------------------------------------- */
/* FINAL OUTPUT */
/*   1. “summary”  – total sessions per channel, ranked                    */
/*   2. “daily”    – daily sessions for the 4-th highest-volume channel    */
/* ---------------------------------------------------------------------- */
SELECT
  'summary'         AS report_type,
  channel,
  NULL              AS event_date,
  sessions
FROM ranked

UNION ALL

SELECT
  'daily'           AS report_type,
  s.channel,
  s.event_date,
  COUNT(DISTINCT s.session_key) AS sessions
FROM sessions s
JOIN ranked r
  ON s.channel = r.channel
WHERE r.rn = 4                                      -- only the 4-th highest channel
GROUP BY s.channel, s.event_date
ORDER BY
  report_type,
  CASE WHEN report_type = 'summary' THEN sessions END DESC,
  CASE WHEN report_type = 'daily'   THEN event_date END
;