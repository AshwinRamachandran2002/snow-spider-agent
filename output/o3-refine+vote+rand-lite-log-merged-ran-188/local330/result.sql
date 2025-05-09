WITH
-- first page (landing page) of each session
first_page AS (
    SELECT  al."session",
            al."path"
    FROM    activity_log al
    JOIN    (
              SELECT "session",
                     MIN("stamp") AS first_stamp
              FROM   activity_log
              GROUP  BY "session"
            ) f
            ON  f."session" = al."session"
            AND f.first_stamp = al."stamp"
),
-- last page (exit page) of each session
last_page AS (
    SELECT  al."session",
            al."path"
    FROM    activity_log al
    JOIN    (
              SELECT "session",
                     MAX("stamp") AS last_stamp
              FROM   activity_log
              GROUP  BY "session"
            ) l
            ON  l."session" = al."session"
            AND l.last_stamp = al."stamp"
),
-- combine landing and exit pages, removing any duplicates
landing_exit AS (
    SELECT DISTINCT "session", "path" FROM first_page
    UNION
    SELECT DISTINCT "session", "path" FROM last_page
)
-- count unique sessions per page
SELECT  "path",
        COUNT(DISTINCT "session") AS session_cnt
FROM    landing_exit
GROUP BY "path"
ORDER BY session_cnt DESC, "path";