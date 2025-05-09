WITH first_quickplay AS (           -- users whose FIRST quick‑play happened 1–15 Aug 2018
  SELECT
    user_pseudo_id,
    MIN(event_date) AS first_play_date
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180801' AND '20180815'
    AND LOWER(event_name) LIKE '%quickplay%'
  GROUP BY user_pseudo_id
),
labeled AS (                       -- attach the board (“event type”) recorded on that first play
  SELECT DISTINCT
    fq.user_pseudo_id,
    fq.first_play_date,
    ep.value.string_value AS quickplay_event_type         -- S / M / L
  FROM `firebase-public-project.analytics_153293282.events_*` AS t
  JOIN first_quickplay AS fq
    ON t.user_pseudo_id = fq.user_pseudo_id
   AND t.event_date      = fq.first_play_date
   AND LOWER(t.event_name) LIKE '%quickplay%'
  CROSS JOIN UNNEST(t.event_params) AS ep
  WHERE ep.key = 'board'                                   -- subtype parameter
),
returns AS (                       -- second‑week (day 8‑14) session_start events
  SELECT DISTINCT
    l.user_pseudo_id,
    l.quickplay_event_type
  FROM `firebase-public-project.analytics_153293282.events_*` AS ss
  JOIN labeled AS l
    ON ss.user_pseudo_id = l.user_pseudo_id
  WHERE ss.event_name = 'session_start'
    AND DATE_DIFF(PARSE_DATE('%Y%m%d', ss.event_date),
                  PARSE_DATE('%Y%m%d', l.first_play_date), DAY)
        BETWEEN 8 AND 14
),
retention AS (                      -- retention rate per quick‑play event type
  SELECT
    l.quickplay_event_type,
    SAFE_DIVIDE(COUNT(DISTINCT r.user_pseudo_id),
                COUNT(DISTINCT l.user_pseudo_id)) AS second_week_retention_rate
  FROM labeled AS l
  LEFT JOIN returns AS r
    ON l.user_pseudo_id = r.user_pseudo_id
  GROUP BY l.quickplay_event_type
)
SELECT                                    -- event type with the lowest second‑week retention
  quickplay_event_type,
  ROUND(second_week_retention_rate, 4) AS second_week_retention_rate
FROM retention
ORDER BY second_week_retention_rate ASC
LIMIT 1;