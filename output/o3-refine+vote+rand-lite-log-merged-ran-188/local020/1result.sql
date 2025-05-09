WITH runs_conceded AS (
    SELECT 
        b.bowler                                AS bowler_id,
        SUM(bs.runs_scored) +
        SUM(COALESCE(er.extra_runs,0))          AS total_runs
    FROM ball_by_ball      b
    LEFT JOIN batsman_scored bs
           ON  bs.match_id   = b.match_id
           AND bs.over_id    = b.over_id
           AND bs.ball_id    = b.ball_id
           AND bs.innings_no = b.innings_no
    LEFT JOIN extra_runs    er
           ON  er.match_id   = b.match_id
           AND er.over_id    = b.over_id
           AND er.ball_id    = b.ball_id
           AND er.innings_no = b.innings_no
    GROUP BY b.bowler
),
wickets_taken AS (
    SELECT 
        b.bowler                AS bowler_id,
        COUNT(*)                AS wickets
    FROM wicket_taken w
    JOIN ball_by_ball b
         ON  b.match_id   = w.match_id
         AND b.over_id    = w.over_id
         AND b.ball_id    = w.ball_id
         AND b.innings_no = w.innings_no
    GROUP BY b.bowler
),
bowling_average AS (
    SELECT 
        r.bowler_id,
        r.total_runs * 1.0 / w.wickets   AS avg_per_wicket
    FROM runs_conceded r
    JOIN wickets_taken w
         ON w.bowler_id = r.bowler_id
    WHERE w.wickets > 0
)
SELECT 
    p.player_name
FROM bowling_average ba
JOIN player p
     ON p.player_id = ba.bowler_id
ORDER BY ba.avg_per_wicket ASC, p.player_name
LIMIT 1;