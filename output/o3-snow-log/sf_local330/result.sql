/*  Count, for every page path, the number of distinct sessions
    in which the page appeared either as the first (landing) page
    or the last (exit) page of that session.                             */

WITH landing_pages AS (
    SELECT  "session",
            "path"
    FROM   (
            SELECT  "session",
                    "path",
                    ROW_NUMBER() OVER (PARTITION BY "session"
                                        ORDER BY "stamp") AS rn
            FROM    LOG.LOG.ACTIVITY_LOG
           )
    WHERE   rn = 1                                        -- first page in session
),
exit_pages AS (
    SELECT  "session",
            "path"
    FROM   (
            SELECT  "session",
                    "path",
                    ROW_NUMBER() OVER (PARTITION BY "session"
                                        ORDER BY "stamp" DESC) AS rn
            FROM    LOG.LOG.ACTIVITY_LOG
           )
    WHERE   rn = 1                                        -- last page in session
),
landing_or_exit AS (                                      -- union of landing & exit
    SELECT * FROM landing_pages
    UNION ALL
    SELECT * FROM exit_pages
),
dedup AS (                                                -- one record per (session, path)
    SELECT DISTINCT "session",
                    "path"
    FROM   landing_or_exit
)

SELECT  "path",
        COUNT(DISTINCT "session") AS "unique_sessions_landing_or_exit"
FROM    dedup
GROUP BY "path"
ORDER BY "unique_sessions_landing_or_exit" DESC NULLS LAST,
         "path";