SELECT
    se."path",
    COUNT(DISTINCT se."session") AS total_unique_sessions
FROM (
        /* landing pages per session */
        SELECT  a."session",
                a."path"
        FROM    "activity_log" a
        JOIN   (SELECT  "session",
                        MIN("stamp") AS target_stamp
                FROM    "activity_log"
                GROUP BY "session") l
          ON  a."session" = l."session"
         AND  a."stamp"   = l.target_stamp

        UNION

        /* exit pages per session */
        SELECT  a."session",
                a."path"
        FROM    "activity_log" a
        JOIN   (SELECT  "session",
                        MAX("stamp") AS target_stamp
                FROM    "activity_log"
                GROUP BY "session") x
          ON  a."session" = x."session"
         AND  a."stamp"   = x.target_stamp
) se
GROUP BY se."path";