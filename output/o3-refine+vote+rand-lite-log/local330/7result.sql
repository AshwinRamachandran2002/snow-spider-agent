WITH ranked AS (
    SELECT
        session,
        path,
        stamp,
        ROW_NUMBER() OVER (PARTITION BY session ORDER BY stamp ASC)  AS rn_first,
        ROW_NUMBER() OVER (PARTITION BY session ORDER BY stamp DESC) AS rn_last
    FROM activity_log
),
landing_exit AS (
    /* landing pages */
    SELECT session, path
    FROM ranked
    WHERE rn_first = 1
    UNION
    /* exit pages */
    SELECT session, path
    FROM ranked
    WHERE rn_last = 1
)
SELECT
    path,
    COUNT(DISTINCT session) AS session_cnt
FROM landing_exit
GROUP BY path
ORDER BY session_cnt DESC, path;