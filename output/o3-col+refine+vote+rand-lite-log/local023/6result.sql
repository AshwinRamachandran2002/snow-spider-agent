WITH season5_runs AS (
    SELECT  bb.striker                         AS player_id,
            bs.match_id,
            SUM(bs.runs_scored)                AS runs_in_match
    FROM    batsman_scored  AS bs
    JOIN    ball_by_ball    AS bb
           ON  bb.match_id = bs.match_id
           AND bb.over_id  = bs.over_id
           AND bb.ball_id  = bs.ball_id
    JOIN    "match"         AS m
           ON  m.match_id  = bs.match_id
    WHERE   m.season_id = 5
    GROUP BY bb.striker, bs.match_id
),
avg_runs AS (
    SELECT  player_id,
            AVG(runs_in_match)                 AS avg_runs
    FROM    season5_runs
    GROUP BY player_id
)
SELECT  p.player_name,
        ROUND(ar.avg_runs, 2)                  AS batting_average
FROM    avg_runs           AS ar
JOIN    player             AS p
       ON p.player_id = ar.player_id
ORDER BY batting_average DESC
LIMIT 5;