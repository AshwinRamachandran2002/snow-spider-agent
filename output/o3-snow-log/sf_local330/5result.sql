/*  Count how many distinct sessions each page appears in
    as a landing page, an exit page, or both (counted once per session) */
WITH landing AS (
    SELECT
        "session",
        "path" AS "page"
    FROM (
        SELECT
            "session",
            "path",
            ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp" ASC) AS rn
        FROM LOG.LOG.ACTIVITY_LOG
    )
    WHERE rn = 1
), exit AS (
    SELECT
        "session",
        "path" AS "page"
    FROM (
        SELECT
            "session",
            "path",
            ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp" DESC) AS rn
        FROM LOG.LOG.ACTIVITY_LOG
    )
    WHERE rn = 1
), union_pages AS (
    /* combine landing-page and exit-page rows,
       keep one record per (session,page) pair */
    SELECT * FROM landing
    UNION
    SELECT * FROM exit
)
SELECT
    "page",
    COUNT(DISTINCT "session") AS "total_unique_sessions"
FROM union_pages
GROUP BY "page"
ORDER BY "total_unique_sessions" DESC NULLS LAST;