WITH
    max_games AS (
        SELECT MAX(g) AS max_g
        FROM BASEBALL.BASEBALL.BATTING
    ),
    max_runs AS (
        SELECT MAX(TO_NUMBER(r)) AS max_r
        FROM BASEBALL.BASEBALL.BATTING
    ),
    max_hits AS (
        SELECT MAX(TO_NUMBER(h)) AS max_h
        FROM BASEBALL.BASEBALL.BATTING
    ),
    max_hr AS (
        SELECT MAX(TO_NUMBER(hr)) AS max_hr
        FROM BASEBALL.BASEBALL.BATTING
    )

SELECT
       'Games Played'                        AS metric,
       p.name_given                          AS given_name,
       CAST(b.g AS NUMBER)                   AS value
FROM   BASEBALL.BASEBALL.BATTING b
JOIN   max_games mg  ON b.g = mg.max_g
JOIN   BASEBALL.BASEBALL.PLAYER p ON p.player_id = b.player_id

UNION ALL

SELECT
       'Runs',
       p.name_given,
       CAST(TO_NUMBER(b.r) AS NUMBER)
FROM   BASEBALL.BASEBALL.BATTING b
JOIN   max_runs mr  ON TO_NUMBER(b.r) = mr.max_r
JOIN   BASEBALL.BASEBALL.PLAYER p ON p.player_id = b.player_id

UNION ALL

SELECT
       'Hits',
       p.name_given,
       CAST(TO_NUMBER(b.h) AS NUMBER)
FROM   BASEBALL.BASEBALL.BATTING b
JOIN   max_hits mh ON TO_NUMBER(b.h) = mh.max_h
JOIN   BASEBALL.BASEBALL.PLAYER p ON p.player_id = b.player_id

UNION ALL

SELECT
       'Home Runs',
       p.name_given,
       CAST(TO_NUMBER(b.hr) AS NUMBER)
FROM   BASEBALL.BASEBALL.BATTING b
JOIN   max_hr mhr ON TO_NUMBER(b.hr) = mhr.max_hr
JOIN   BASEBALL.BASEBALL.PLAYER p ON p.player_id = b.player_id

ORDER BY metric;