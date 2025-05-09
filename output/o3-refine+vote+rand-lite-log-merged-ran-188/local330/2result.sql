WITH
-- find the earliest and latest time stamp for every session
stamp_range AS (
    SELECT
        session,
        MIN(datetime(stamp)) AS first_stamp,
        MAX(datetime(stamp)) AS last_stamp
    FROM activity_log
    GROUP BY session
),
-- pages that are the first (landing) page of each session
landing AS (
    SELECT
        al.session,
        al.path
    FROM activity_log AS al
    JOIN stamp_range AS sr
      ON al.session = sr.session
     AND datetime(al.stamp) = sr.first_stamp
),
-- pages that are the last (exit) page of each session
exit AS (
    SELECT
        al.session,
        al.path
    FROM activity_log AS al
    JOIN stamp_range AS sr
      ON al.session = sr.session
     AND datetime(al.stamp) = sr.last_stamp
),
-- combine landing and exit pages, removing duplicates within the same session
landing_exit AS (
    SELECT session, path FROM landing
    UNION
    SELECT session, path FROM exit
)
-- count distinct sessions per page
SELECT
    path,
    COUNT(DISTINCT session) AS session_count
FROM landing_exit
GROUP BY path
ORDER BY session_count DESC, path;