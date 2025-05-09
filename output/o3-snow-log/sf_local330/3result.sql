/*  Count distinct sessions for every page that appears
    as either the FIRST (landing) or LAST (exit) page
    visited within a session                                       */

WITH
-- 1) landing page (row‐number = 1 when ordering asc by time)
landing AS (
    SELECT
        "session",
        "path" AS "page_path"
    FROM (
        SELECT
            "session",
            "path",
            ROW_NUMBER() OVER (
                PARTITION BY "session"
                ORDER BY TO_TIMESTAMP("stamp")          -- earliest first
            ) AS rn
        FROM LOG.LOG.ACTIVITY_LOG
    )
    WHERE rn = 1
),

-- 2) exit page (row‐number = 1 when ordering desc by time)
exit AS (
    SELECT
        "session",
        "path" AS "page_path"
    FROM (
        SELECT
            "session",
            "path",
            ROW_NUMBER() OVER (
                PARTITION BY "session"
                ORDER BY TO_TIMESTAMP("stamp") DESC     -- latest first
            ) AS rn
        FROM LOG.LOG.ACTIVITY_LOG
    )
    WHERE rn = 1
),

-- 3) union landing & exit, one row per (session, page)
union_pages AS (
    SELECT * FROM landing
    UNION
    SELECT * FROM exit
)

-- 4) final aggregation
SELECT
    "page_path",
    COUNT(DISTINCT "session") AS "unique_sessions"
FROM union_pages
GROUP BY "page_path"
ORDER BY "unique_sessions" DESC NULLS LAST;