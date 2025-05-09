/*  Total unique sessions in which each page appears 
    as either a landing page, an exit page, or both           */

WITH landing AS (         -- first page within each session
    SELECT DISTINCT
           "session",
           "path"  AS "page"
    FROM (
        SELECT
               "session",
               "path",
               ROW_NUMBER() OVER (PARTITION BY "session"
                                   ORDER BY "stamp" ASC) AS rn
        FROM LOG.LOG.ACTIVITY_LOG
    )
    WHERE rn = 1
),
exit AS (            -- last page within each session
    SELECT DISTINCT
           "session",
           "path"  AS "page"
    FROM (
        SELECT
               "session",
               "path",
               ROW_NUMBER() OVER (PARTITION BY "session"
                                   ORDER BY "stamp" DESC) AS rn
        FROM LOG.LOG.ACTIVITY_LOG
    )
    WHERE rn = 1
),
landing_or_exit AS ( -- combine, counting a session-page only once
    SELECT * FROM landing
    UNION
    SELECT * FROM exit
)

SELECT
       "page",
       COUNT(DISTINCT "session") AS "unique_session_cnt"
FROM landing_or_exit
GROUP BY "page"
ORDER BY "unique_session_cnt" DESC NULLS LAST;