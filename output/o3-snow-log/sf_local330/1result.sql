/* -----------------------------------------------------------
   Landing  OR exit sessions per page
   ----------------------------------------------------------- */
WITH first_pages AS (   /* 1. landing page for each session */
    SELECT
        "session",
        "path"
    FROM LOG.LOG.ACTIVITY_LOG
    QUALIFY "stamp" = MIN("stamp") OVER (PARTITION BY "session")
),
last_pages AS (        /* 2. exit page for each session   */
    SELECT
        "session",
        "path"
    FROM LOG.LOG.ACTIVITY_LOG
    QUALIFY "stamp" = MAX("stamp") OVER (PARTITION BY "session")
),
both AS (              /* 3. union-distinct landing & exit */
    SELECT DISTINCT
        "session",
        "path"
    FROM first_pages
    UNION DISTINCT
    SELECT DISTINCT
        "session",
        "path"
    FROM last_pages
)
SELECT                  /* 4. count unique sessions per page */
    "path"                         AS "page",
    COUNT(DISTINCT "session")      AS "sessions_landing_or_exit"
FROM both
GROUP BY "path"
ORDER BY "sessions_landing_or_exit" DESC NULLS LAST;