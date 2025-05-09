/* -----------------------------------------------------------
   1. first_conv  : first time each session reached /detail or /complete
   2. pre_events  : events (non-empty search_type) that occurred BEFORE the first conversion
   3. cnt         : number of such pre-conversion events per session
   4. min_cnt     : the minimum of those counts
   5. target_sessions : sessions whose count equals the minimum
   6. final SELECT: paths & search_type for all qualifying sessions
   ----------------------------------------------------------- */
WITH first_conv AS (
    SELECT
        "session",
        MIN("stamp") AS "first_conv_stamp"
    FROM LOG.LOG.ACTIVITY_LOG
    WHERE LOWER("path") LIKE '%/detail%'
       OR LOWER("path") LIKE '%/complete%'
    GROUP BY "session"
),
pre_events AS (
    SELECT
        a."session",
        a."path",
        a."search_type",
        a."stamp"
    FROM LOG.LOG.ACTIVITY_LOG AS a
    JOIN first_conv AS f
      ON a."session" = f."session"
    WHERE COALESCE(a."search_type", '') <> ''
      AND a."stamp" < f."first_conv_stamp"
),
cnt AS (
    SELECT
        "session",
        COUNT(*) AS "pre_conv_cnt"
    FROM pre_events
    GROUP BY "session"
),
min_cnt AS (
    SELECT MIN("pre_conv_cnt") AS "min_cnt" FROM cnt
),
target_sessions AS (
    SELECT c."session"
    FROM cnt          AS c
    JOIN min_cnt      AS m
      ON c."pre_conv_cnt" = m."min_cnt"
)
SELECT
    p."session",
    p."path",
    p."search_type"
FROM pre_events AS p
JOIN target_sessions AS t
  ON p."session" = t."session"
ORDER BY
    p."session",
    p."stamp";