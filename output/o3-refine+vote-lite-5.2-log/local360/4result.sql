WITH first_dc AS (                        -- 1. first “/detail” click or “/complete” conversion per session
    SELECT
        session,
        MIN(stamp) AS first_dc_stamp
    FROM activity_log
    WHERE path LIKE '%/detail%' OR path LIKE '%/complete%'
    GROUP BY session
),
pre_events AS (                           -- 2. events (non‑empty search_type) occurring before that moment
    SELECT
        al.session,
        al.path,
        al.search_type,
        al.stamp
    FROM activity_log AS al
    JOIN first_dc        AS fd ON al.session = fd.session
    WHERE al.search_type IS NOT NULL
      AND al.search_type <> ''
      AND al.stamp < fd.first_dc_stamp
),
pre_cnt AS (                              -- 3. count of such events per session
    SELECT
        fd.session,
        COUNT(pe.session) AS cnt
    FROM first_dc AS fd
    LEFT JOIN pre_events AS pe ON fd.session = pe.session
    GROUP BY fd.session
),
min_cnt AS (                              -- 4. minimum count
    SELECT MIN(cnt) AS min_cnt FROM pre_cnt
),
target_sessions AS (                      -- 5. sessions whose count equals the minimum
    SELECT session
    FROM pre_cnt
    WHERE cnt = (SELECT min_cnt FROM min_cnt)
)
SELECT                                    -- 6. return those sessions with their corresponding path & search_type
    ts.session,
    pe.path,
    pe.search_type
FROM target_sessions AS ts
LEFT JOIN pre_events AS pe ON ts.session = pe.session
ORDER BY ts.session, pe.stamp;