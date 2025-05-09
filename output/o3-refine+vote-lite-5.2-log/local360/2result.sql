WITH first_conv AS (
    /* first “/detail” click or “/complete” conversion for every session */
    SELECT
        "session",
        MIN(stamp) AS first_conv_stamp
    FROM activity_log
    WHERE path    LIKE '%/detail%'   OR path LIKE '%/complete%'
       OR "option" =  'detail'       OR "option" =  'complete'
    GROUP BY "session"
),
pre_events AS (
    /* events that happened BEFORE that conversion and have a non‑empty search_type */
    SELECT
        a."session",
        a.path,
        a.search_type,
        a.stamp
    FROM activity_log AS a
    JOIN first_conv  AS f
      ON a."session" = f."session"
     AND a.stamp     < f.first_conv_stamp
    WHERE a.search_type IS NOT NULL
      AND a.search_type <> ''
),
cnt AS (
    /* how many such events per session */
    SELECT
        "session",
        COUNT(*) AS pre_event_cnt
    FROM pre_events
    GROUP BY "session"
),
min_cnt AS (
    /* minimum of those counts */
    SELECT MIN(pre_event_cnt) AS min_cnt FROM cnt
),
target_sessions AS (
    /* sessions that have the minimum count */
    SELECT "session"
    FROM cnt
    WHERE pre_event_cnt = (SELECT min_cnt FROM min_cnt)
)
SELECT
    p."session",
    p.path,
    p.search_type
FROM pre_events AS p
JOIN target_sessions AS t
  ON p."session" = t."session"
ORDER BY p."session", p.stamp;