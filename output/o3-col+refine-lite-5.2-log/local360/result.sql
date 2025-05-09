WITH first_target AS (
    /* 1.  First '/detail' or '/complete' event in each session */
    SELECT
        "session",
        MIN("stamp") AS first_target_stamp
    FROM "activity_log"
    WHERE "path" LIKE '%/detail%'     -- click to detail page
       OR "path" LIKE '%/complete%'   -- conversion page
    GROUP BY "session"
),
pre_counts AS (
    /* 2.  Count events (with non‑empty search_type) occurring BEFORE that first target */
    SELECT
        a."session",
        COUNT(*) AS pre_event_cnt
    FROM "activity_log" a
    JOIN first_target f
      ON a."session" = f."session"
    WHERE a."stamp" < f.first_target_stamp
      AND a."search_type" IS NOT NULL
      AND TRIM(a."search_type") <> ''
    GROUP BY a."session"
),
min_cnt AS (
    /* 3.  Global minimum of those pre‑event counts */
    SELECT MIN(pre_event_cnt) AS cnt
    FROM pre_counts
),
qualifying_sessions AS (
    /* 4.  Sessions whose pre‑event count equals that minimum */
    SELECT p."session"
    FROM pre_counts p
    JOIN min_cnt m ON p.pre_event_cnt = m.cnt
)
-- 5.  Final output: every (session, path, search_type) pair that meets all conditions
SELECT
    a."session",
    a."path",
    a."search_type"
FROM "activity_log" a
JOIN first_target f
  ON a."session" = f."session"
JOIN qualifying_sessions q
  ON a."session" = q."session"
WHERE a."stamp" < f.first_target_stamp          -- only events before first target
  AND a."search_type" IS NOT NULL
  AND TRIM(a."search_type") <> ''               -- non‑empty search_type
ORDER BY a."session", a."stamp";                -- deterministic presentation