/*----------------------------------------------------------
  Compute, for every page, the number of unique sessions in
  which the page is seen as either the landing page (first  
  page of the session) or the exit page (last page of the   
  session).  Each session is counted only once per page.    
----------------------------------------------------------*/
WITH landing AS (      -- first page per session
    SELECT
        "session",
        "path"
    FROM LOG.LOG.ACTIVITY_LOG
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp" ASC) = 1
),
exit AS (              -- last page per session
    SELECT
        "session",
        "path"
    FROM LOG.LOG.ACTIVITY_LOG
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp" DESC) = 1
),
combined AS (          -- union of landing & exit pages (de-duplicated)
    SELECT DISTINCT "session", "path" FROM landing
    UNION
    SELECT DISTINCT "session", "path" FROM exit
)
SELECT
    "path"                           AS "page",
    COUNT(DISTINCT "session")        AS "total_unique_sessions"
FROM combined
GROUP BY "path"
ORDER BY "total_unique_sessions" DESC NULLS LAST;