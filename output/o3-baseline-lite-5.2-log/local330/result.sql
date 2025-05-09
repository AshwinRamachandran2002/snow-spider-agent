WITH ordered AS (
    SELECT
        session,
        path,
        stamp,
        ROW_NUMBER() OVER (PARTITION BY session ORDER BY datetime(stamp))  AS rn_first,
        ROW_NUMBER() OVER (PARTITION BY session ORDER BY datetime(stamp) DESC) AS rn_last
    FROM activity_log
),
landing_exit_pages AS (
    /* first page of the session */
    SELECT session, path
    FROM ordered
    WHERE rn_first = 1

    UNION    /* UNION removes duplicates => a page counted once per session even if it is both first & last */

    /* last page of the session */
    SELECT session, path
    FROM ordered
    WHERE rn_last = 1
)
SELECT
    path,                          -- web page
    COUNT(DISTINCT session) AS session_count   -- number of unique sessions in which it is landing or exit
FROM landing_exit_pages
GROUP BY path
ORDER BY session_count DESC, path;