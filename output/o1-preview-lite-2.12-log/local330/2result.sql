SELECT page, COUNT(DISTINCT session) AS SessionCount
FROM (
    -- Starting pages from activity_log
    SELECT DISTINCT a.session, a.path AS page
    FROM activity_log a
    INNER JOIN (
        SELECT session, MIN(stamp) AS first_stamp
        FROM activity_log
        GROUP BY session
    ) b
    ON a.session = b.session AND a.stamp = b.first_stamp

    UNION

    -- Ending pages from activity_log
    SELECT DISTINCT a.session, a.path AS page
    FROM activity_log a
    INNER JOIN (
        SELECT session, MAX(stamp) AS last_stamp
        FROM activity_log
        GROUP BY session
    ) b
    ON a.session = b.session AND a.stamp = b.last_stamp

    UNION

    -- Starting pages from read_log
    SELECT DISTINCT a.session, a.url AS page
    FROM read_log a
    INNER JOIN (
        SELECT session, MIN(stamp) AS first_stamp
        FROM read_log
        GROUP BY session
    ) b
    ON a.session = b.session AND a.stamp = b.first_stamp

    UNION

    -- Ending pages from read_log
    SELECT DISTINCT a.session, a.url AS page
    FROM read_log a
    INNER JOIN (
        SELECT session, MAX(stamp) AS last_stamp
        FROM read_log
        GROUP BY session
    ) b
    ON a.session = b.session AND a.stamp = b.last_stamp
) AS all_pages
GROUP BY page
ORDER BY SessionCount DESC;