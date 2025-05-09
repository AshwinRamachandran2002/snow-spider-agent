WITH
-- pick the first (landing) record of every session
landing AS (
    SELECT al.session,
           al.path
    FROM activity_log al
    JOIN (
        SELECT session,
               MIN(stamp) AS first_stamp
        FROM activity_log
        GROUP BY session
    ) t
      ON al.session = t.session
     AND al.stamp   = t.first_stamp
),
-- pick the last (exit) record of every session
exit AS (
    SELECT al.session,
           al.path
    FROM activity_log al
    JOIN (
        SELECT session,
               MAX(stamp) AS last_stamp
        FROM activity_log
        GROUP BY session
    ) t
      ON al.session = t.session
     AND al.stamp   = t.last_stamp
),
-- combine landing and exit pages, keeping each (path, session) only once
landing_exit AS (
    SELECT session, path FROM landing
    UNION
    SELECT session, path FROM exit
)
-- count unique sessions per page
SELECT
       path,
       COUNT(DISTINCT session) AS unique_session_count
FROM   landing_exit
GROUP  BY path
ORDER  BY unique_session_count DESC, path;