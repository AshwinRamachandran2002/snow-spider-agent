WITH activity_first_last AS (
    SELECT session, MIN(stamp) AS first_stamp, MAX(stamp) AS last_stamp
    FROM activity_log
    GROUP BY session
),
activity_first_pages AS (
    SELECT a.session, a.path AS page
    FROM activity_log a
    JOIN activity_first_last f ON a.session = f.session AND a.stamp = f.first_stamp
),
activity_last_pages AS (
    SELECT a.session, a.path AS page
    FROM activity_log a
    JOIN activity_first_last f ON a.session = f.session AND a.stamp = f.last_stamp
),
read_first_last AS (
    SELECT session, MIN(stamp) AS first_stamp, MAX(stamp) AS last_stamp
    FROM read_log
    GROUP BY session
),
read_first_pages AS (
    SELECT r.session, r.url AS page
    FROM read_log r
    JOIN read_first_last f ON r.session = f.session AND r.stamp = f.first_stamp
),
read_last_pages AS (
    SELECT r.session, r.url AS page
    FROM read_log r
    JOIN read_first_last f ON r.session = f.session AND r.stamp = f.last_stamp
),
all_pages AS (
    SELECT page, session FROM activity_first_pages
    UNION ALL
    SELECT page, session FROM activity_last_pages
    UNION ALL
    SELECT page, session FROM read_first_pages
    UNION ALL
    SELECT page, session FROM read_last_pages
)
SELECT page, COUNT(DISTINCT session) AS SessionCount
FROM all_pages
GROUP BY page
ORDER BY SessionCount DESC;