/* ------------------------------------------------------------
   Sessions that performed the fewest “search_type” actions
   before their very first  /detail  or  /complete  page view.
   For every such session, list each qualifying pre-hit event
   together with its path and search_type.
-------------------------------------------------------------*/
WITH first_hit AS (          -- 1) first /detail or /complete per session
    SELECT
        "session",
        MIN(TO_TIMESTAMP_NTZ("stamp")) AS "first_hit_stamp"
    FROM LOG.LOG.ACTIVITY_LOG
    WHERE LOWER("path") LIKE '%/detail%'
       OR LOWER("path") LIKE '%/complete%'
    GROUP BY "session"
),
pre_cnt AS (                 -- 2) count of non-blank search_type events that happened BEFORE that hit
    SELECT
        a."session",
        COUNT(*) AS "pre_hit_search_cnt"
    FROM LOG.LOG.ACTIVITY_LOG a
    JOIN first_hit f
      ON a."session" = f."session"
    WHERE TO_TIMESTAMP_NTZ(a."stamp") < f."first_hit_stamp"
      AND a."search_type" <> ''
    GROUP BY a."session"
),
min_cnt AS (                 -- 3) the minimum of those counts
    SELECT MIN("pre_hit_search_cnt") AS "min_cnt"
    FROM pre_cnt
),
target_sessions AS (         -- 4) all sessions whose count equals the minimum
    SELECT p."session"
    FROM pre_cnt  p
    JOIN min_cnt m
      ON p."pre_hit_search_cnt" = m."min_cnt"
)
-- 5) return every pre-hit event for the target sessions
SELECT
    a."session",
    a."path",
    a."search_type",
    a."stamp"
FROM LOG.LOG.ACTIVITY_LOG a
JOIN first_hit       f ON a."session" = f."session"        -- to know the cut-off
JOIN target_sessions t ON a."session" = t."session"
WHERE a."search_type" <> ''                                -- same condition used in counting
  AND TO_TIMESTAMP_NTZ(a."stamp") < f."first_hit_stamp"    -- only events BEFORE the first hit
ORDER BY
    a."session",
    TO_TIMESTAMP_NTZ(a."stamp");