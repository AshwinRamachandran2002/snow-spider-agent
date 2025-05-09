WITH first_conv AS (                     -- ① first “/detail” click or “/complete” conversion
    SELECT
        session,
        MIN(stamp) AS first_conv_stamp
    FROM activity_log
    WHERE path LIKE '/detail%'            -- click on a detail page
       OR path LIKE '/complete%'          -- or a conversion‐complete page
    GROUP BY session
),
pre_cnt AS (                             -- ② how many search‑type events happened **before** the first conversion
    SELECT
        fc.session,
        SUM(
            CASE
                WHEN a.stamp < fc.first_conv_stamp
                     AND a.search_type IS NOT NULL
                     AND a.search_type <> ''
                THEN 1
                ELSE 0
            END
        ) AS cnt
    FROM first_conv  fc
    JOIN activity_log a
      ON a.session = fc.session
    GROUP BY fc.session
),
min_cnt AS (                             -- ③ the minimum of those counts
    SELECT MIN(cnt) AS min_cnt
    FROM   pre_cnt
),
target_sessions AS (                     -- ④ sessions whose pre‑event count equals the minimum
    SELECT pc.session
    FROM   pre_cnt pc
    JOIN   min_cnt mc ON pc.cnt = mc.min_cnt
),
pre_events AS (                          -- ⑤ the actual pre‑events (with non‑empty search_type)
    SELECT
        a.session,
        a.path,
        a.search_type,
        a.stamp
    FROM   activity_log a
    JOIN   first_conv      fc ON a.session = fc.session
    JOIN   target_sessions ts ON a.session = ts.session
    WHERE  a.stamp < fc.first_conv_stamp
      AND  a.search_type IS NOT NULL
      AND  a.search_type <> ''
)
SELECT
    ts.session,
    pe.path,
    pe.search_type
FROM   target_sessions ts
LEFT   JOIN pre_events pe ON ts.session = pe.session      -- keeps sessions that have zero such events
ORDER  BY ts.session,
          pe.stamp;