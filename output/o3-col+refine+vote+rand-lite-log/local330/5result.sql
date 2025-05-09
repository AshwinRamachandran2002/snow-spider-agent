WITH landing AS (
    -- first page (minimum timestamp) in each session
    SELECT al."session",
           al."path"
    FROM   "activity_log" al
    JOIN  (
        SELECT "session",
               MIN("stamp") AS first_stamp
        FROM   "activity_log"
        GROUP  BY "session"
    ) f
      ON  al."session" = f."session"
     AND al."stamp"   = f."first_stamp"
),
exit AS (
    -- last page (maximum timestamp) in each session
    SELECT al."session",
           al."path"
    FROM   "activity_log" al
    JOIN  (
        SELECT "session",
               MAX("stamp") AS last_stamp
        FROM   "activity_log"
        GROUP  BY "session"
    ) e
      ON  al."session" = e."session"
     AND al."stamp"   = e."last_stamp"
),
landing_exit AS (
    -- combine landing & exit pages; UNION removes duplicates
    SELECT * FROM landing
    UNION
    SELECT * FROM exit
)
SELECT   "path",
         COUNT(DISTINCT "session") AS "unique_sessions"
FROM     landing_exit
GROUP BY "path"
ORDER BY "unique_sessions" DESC;