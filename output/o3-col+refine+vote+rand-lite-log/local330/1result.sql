SELECT
    le."path",
    COUNT(DISTINCT le."session") AS landing_or_exit_sessions
FROM (
        /* landing pages */
        SELECT  al."session",
                al."path"
        FROM    "activity_log" AS al
        JOIN    (
                    SELECT  "session",
                            MIN("stamp") AS first_stamp
                    FROM    "activity_log"
                    GROUP BY "session"
                ) AS f
          ON al."session" = f."session"
         AND al."stamp"   = f."first_stamp"

        UNION

        /* exit pages */
        SELECT  al."session",
                al."path"
        FROM    "activity_log" AS al
        JOIN    (
                    SELECT  "session",
                            MAX("stamp") AS last_stamp
                    FROM    "activity_log"
                    GROUP BY "session"
                ) AS l
          ON al."session" = l."session"
         AND al."stamp"   = l."last_stamp"
) AS le
GROUP BY le."path"
ORDER BY landing_or_exit_sessions DESC;