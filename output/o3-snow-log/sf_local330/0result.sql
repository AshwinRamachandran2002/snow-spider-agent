/*---------------------------------------------------------------
  Count distinct sessions per page where the page appears as
  the landing page (first by time) OR the exit page (last by time)
----------------------------------------------------------------*/
WITH landing AS (          -- 1. first page in each session
    SELECT
        "session",
        "path"
    FROM (
        SELECT
            "session",
            "path",
            ROW_NUMBER() OVER (
                PARTITION BY "session"
                ORDER BY TO_TIMESTAMP("stamp") ASC
            ) AS rn
        FROM "LOG"."LOG"."ACTIVITY_LOG"
    )
    WHERE rn = 1
),
exit_page AS (             -- 2. last page in each session
    SELECT
        "session",
        "path"
    FROM (
        SELECT
            "session",
            "path",
            ROW_NUMBER() OVER (
                PARTITION BY "session"
                ORDER BY TO_TIMESTAMP("stamp") DESC
            ) AS rn
        FROM "LOG"."LOG"."ACTIVITY_LOG"
    )
    WHERE rn = 1
),
combined AS (              -- 3. landing UNION exit (deduped)
    SELECT * FROM landing
    UNION
    SELECT * FROM exit_page
)
SELECT                      -- 4. final count per page
    "path",
    COUNT(DISTINCT "session") AS "unique_sessions"
FROM combined
GROUP BY "path"
ORDER BY "unique_sessions" DESC NULLS LAST;