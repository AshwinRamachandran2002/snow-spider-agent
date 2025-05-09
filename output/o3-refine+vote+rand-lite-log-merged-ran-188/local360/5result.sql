WITH first_conv AS (
    /* first /detail or /complete time (if any) per session */
    SELECT
        session,
        MIN(stamp) AS first_conv_stamp
    FROM activity_log
    WHERE path LIKE '%/detail%' OR path LIKE '%/complete%'
    GROUP BY session
),
pre_events AS (
    /* events having non‑empty search_type that occur before the first conversion */
    SELECT
        a.session,
        a.path,
        a.search_type,
        a.stamp
    FROM activity_log AS a
    LEFT JOIN first_conv AS f
           ON a.session = f.session
    WHERE a.search_type IS NOT NULL
      AND a.search_type <> ''
      AND (f.first_conv_stamp IS NULL OR a.stamp < f.first_conv_stamp)
),
cnt_per_session AS (
    /* how many such events exist per session */
    SELECT
        session,
        COUNT(*) AS cnt
    FROM pre_events
    GROUP BY session
),
min_cnt AS (
    /* the minimum of those counts */
    SELECT MIN(cnt) AS min_cnt_value
    FROM cnt_per_session
),
target_sessions AS (
    /* sessions whose count equals the minimum */
    SELECT session
    FROM cnt_per_session
    WHERE cnt = (SELECT min_cnt_value FROM min_cnt)
)
SELECT
    p.session,
    p.path,
    p.search_type
FROM pre_events AS p
JOIN target_sessions AS t
  ON p.session = t.session
ORDER BY
    p.session,
    p.stamp;