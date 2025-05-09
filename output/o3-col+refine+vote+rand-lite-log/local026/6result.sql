WITH over_totals AS (               -- runs conceded by every bowler in every over
    SELECT  b.match_id,
            b.over_id,
            b.bowler,
            SUM(COALESCE(bs.runs_scored,0) + COALESCE(er.extra_runs,0)) AS runs_in_over
    FROM    ball_by_ball   AS b
    LEFT JOIN batsman_scored AS bs
           ON  bs.match_id   = b.match_id
           AND bs.over_id    = b.over_id
           AND bs.ball_id    = b.ball_id
           AND bs.innings_no = b.innings_no
    LEFT JOIN extra_runs     AS er
           ON  er.match_id   = b.match_id
           AND er.over_id    = b.over_id
           AND er.ball_id    = b.ball_id
           AND er.innings_no = b.innings_no
    GROUP BY b.match_id, b.over_id, b.bowler
),
max_in_match AS (                   -- most-expensive over in each match
    SELECT  match_id,
            MAX(runs_in_over) AS max_runs
    FROM    over_totals
    GROUP BY match_id
),
costly_overs AS (                   -- keep only those overs that are the max of their match
    SELECT  o.match_id,
            o.bowler,
            o.runs_in_over
    FROM    over_totals o
    JOIN    max_in_match m
           ON m.match_id = o.match_id
          AND m.max_runs = o.runs_in_over
)
SELECT  p.player_name  AS bowler_name,
        c.match_id,
        c.runs_in_over AS runs_conceded
FROM    costly_overs c
JOIN    player       p ON p.player_id = c.bowler
ORDER BY c.runs_in_over DESC
LIMIT 3;