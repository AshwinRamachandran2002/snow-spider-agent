/*  Players who hold the all-time single-season bests for
    Games Played, Runs, Hits, and Home Runs, together with
    their given names and the record value obtained          */

WITH metric_max AS (
    SELECT
        MAX(g)                        AS max_g,
        MAX(TRY_TO_NUMBER(r))         AS max_r,
        MAX(TRY_TO_NUMBER(h))         AS max_h,
        MAX(TRY_TO_NUMBER(hr))        AS max_hr
    FROM BASEBALL.BASEBALL.BATTING
),

games_max AS (
    SELECT
        'GAMES_PLAYED'                AS metric,
        b.g                           AS score,
        p.name_given
    FROM BASEBALL.BASEBALL.BATTING b
    JOIN metric_max m  ON b.g = m.max_g
    JOIN BASEBALL.BASEBALL.PLAYER  p ON p.player_id = b.player_id
),

runs_max AS (
    SELECT
        'RUNS'                        AS metric,
        TRY_TO_NUMBER(b.r)            AS score,
        p.name_given
    FROM BASEBALL.BASEBALL.BATTING b
    JOIN metric_max m  ON TRY_TO_NUMBER(b.r) = m.max_r
    JOIN BASEBALL.BASEBALL.PLAYER  p ON p.player_id = b.player_id
),

hits_max AS (
    SELECT
        'HITS'                        AS metric,
        TRY_TO_NUMBER(b.h)            AS score,
        p.name_given
    FROM BASEBALL.BASEBALL.BATTING b
    JOIN metric_max m  ON TRY_TO_NUMBER(b.h) = m.max_h
    JOIN BASEBALL.BASEBALL.PLAYER  p ON p.player_id = b.player_id
),

hr_max AS (
    SELECT
        'HOME_RUNS'                   AS metric,
        TRY_TO_NUMBER(b.hr)           AS score,
        p.name_given
    FROM BASEBALL.BASEBALL.BATTING b
    JOIN metric_max m  ON TRY_TO_NUMBER(b.hr) = m.max_hr
    JOIN BASEBALL.BASEBALL.PLAYER  p ON p.player_id = b.player_id
)

SELECT
    metric,
    score,
    name_given
FROM (
        SELECT * FROM games_max
        UNION ALL
        SELECT * FROM runs_max
        UNION ALL
        SELECT * FROM hits_max
        UNION ALL
        SELECT * FROM hr_max
     )
ORDER BY metric;