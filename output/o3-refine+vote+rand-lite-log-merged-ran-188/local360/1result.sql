WITH first_cv AS (           -- ① first '/detail' click or '/complete' conversion time per session
    SELECT
        session,
        MIN(stamp) AS first_cv_stamp
    FROM activity_log
    WHERE path LIKE '%/detail%'
       OR path LIKE '%/complete%'
    GROUP BY session
),
pre_events AS (              -- ② events (having non‑empty search_type) that happened before the first conversion
    SELECT
        al.session,
        al.stamp,
        al.path,
        al.search_type
    FROM activity_log AS al
    JOIN first_cv  AS cv  ON al.session = cv.session
    WHERE al.stamp < cv.first_cv_stamp
      AND al.search_type IS NOT NULL
      AND al.search_type <> ''
),
pre_counts AS (              -- ③ how many such events per session
    SELECT
        session,
        COUNT(*) AS cnt
    FROM pre_events
    GROUP BY session
),
min_cnt AS (                 -- ④ minimum count among all sessions
    SELECT MIN(cnt) AS mcnt
    FROM pre_counts
),
target_sessions AS (         -- ⑤ sessions whose count equals the minimum
    SELECT pc.session
    FROM pre_counts pc, min_cnt m
    WHERE pc.cnt = m.mcnt
)
-- ⑥ return the session(s) with the minimum pre‑conversion event count,
--    along with their corresponding path and search_type
SELECT
    pe.session,
    pe.path,
    pe.search_type
FROM pre_events  AS pe
JOIN target_sessions AS ts ON pe.session = ts.session
ORDER BY
    pe.session,
    pe.stamp;