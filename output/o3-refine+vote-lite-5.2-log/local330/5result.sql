WITH session_limits AS (
    /* find first and last time‑stamps for every session */
    SELECT
        session,
        MIN(stamp) AS first_ts,
        MAX(stamp) AS last_ts
    FROM activity_log
    GROUP BY session
),
landing AS (
    /* landing page(s): rows whose time‑stamp equals the session’s first time‑stamp */
    SELECT
        al.session,
        al.path
    FROM activity_log AS al
    JOIN session_limits AS sl
      ON al.session = sl.session
     AND al.stamp  = sl.first_ts
    WHERE al.path IS NOT NULL
),
exit AS (
    /* exit page(s): rows whose time‑stamp equals the session’s last time‑stamp */
    SELECT
        al.session,
        al.path
    FROM activity_log AS al
    JOIN session_limits AS sl
      ON al.session = sl.session
     AND al.stamp  = sl.last_ts
    WHERE al.path IS NOT NULL
),
landing_exit AS (
    /* combine landing and exit pages, removing duplicates within the same session */
    SELECT session, path FROM landing
    UNION
    SELECT session, path FROM exit
)
SELECT
    path,
    COUNT(DISTINCT session) AS unique_session_count
FROM landing_exit
GROUP BY path
ORDER BY unique_session_count DESC, path;