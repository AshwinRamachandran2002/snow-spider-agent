WITH career AS (
    /* 1.  Aggregate every player’s lifetime totals */
    SELECT
        player_id,
        SUM(g)                             AS total_g,
        SUM(TRY_TO_NUMBER(r))              AS total_r,
        SUM(TRY_TO_NUMBER(h))              AS total_h,
        SUM(TRY_TO_NUMBER(hr))             AS total_hr
    FROM BASEBALL.BASEBALL.BATTING
    GROUP BY player_id
),
max_vals AS (
    /* 2.  Identify the record (maximum) for each statistic */
    SELECT
        MAX(total_g)  AS max_g,
        MAX(total_r)  AS max_r,
        MAX(total_h)  AS max_h,
        MAX(total_hr) AS max_hr
    FROM career
),
top_players AS (
    /* 3.  Pick all players who match each record value (ties included) */
    SELECT player_id, 'Games Played' AS metric, total_g  AS value FROM career, max_vals WHERE total_g  = max_g
    UNION ALL
    SELECT player_id, 'Runs'         AS metric, total_r  AS value FROM career, max_vals WHERE total_r  = max_r
    UNION ALL
    SELECT player_id, 'Hits'         AS metric, total_h  AS value FROM career, max_vals WHERE total_h  = max_h
    UNION ALL
    SELECT player_id, 'Home Runs'    AS metric, total_hr AS value FROM career, max_vals WHERE total_hr = max_hr
)
SELECT
    p.name_given,
    t.metric,
    t.value
FROM top_players t
JOIN BASEBALL.BASEBALL.PLAYER p
  ON p.player_id = t.player_id
ORDER BY
    CASE
        WHEN t.metric = 'Games Played' THEN 1
        WHEN t.metric = 'Runs'         THEN 2
        WHEN t.metric = 'Hits'         THEN 3
        WHEN t.metric = 'Home Runs'    THEN 4
    END,
    p.name_given;