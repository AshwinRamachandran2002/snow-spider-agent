WITH first_click AS (            -- 1. 1st “/detail” click or “/complete” conversion per session
    SELECT
        session,
        MIN(stamp) AS first_click_stamp
    FROM activity_log
    WHERE path LIKE '%/detail%'           -- click to a detail page
       OR path LIKE '%/complete%'         -- or conversion completion
    GROUP BY session
),
pre_events AS (                  -- 2. events (search_type present) *before* that first click
    SELECT
        al.session,
        al.stamp,
        al.path,
        al.search_type
    FROM activity_log AS al
    JOIN first_click AS fc
      ON al.session = fc.session
     AND al.stamp  < fc.first_click_stamp      -- strictly before the first click
     AND al.search_type IS NOT NULL
     AND al.search_type <> ''                  -- non‑empty search_type only
),
pre_counts AS (                  -- 3. how many such events per session
    SELECT
        session,
        COUNT(*) AS cnt
    FROM pre_events
    GROUP BY session
),
min_cnt AS (                     -- 4. the minimum count
    SELECT MIN(cnt) AS min_cnt FROM pre_counts
),
target_sessions AS (             -- 5. the sessions that have the minimum count
    SELECT session
    FROM pre_counts, min_cnt
    WHERE cnt = min_cnt
)
-- 6. return every counted event (path & search_type) for the target sessions
SELECT
    pe.session,
    pe.path,
    pe.search_type
FROM pre_events AS pe
JOIN target_sessions AS ts USING (session)
ORDER BY pe.session,
         pe.stamp;