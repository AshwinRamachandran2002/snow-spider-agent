WITH runs_conceded AS (
    SELECT 
        b.bowler,
        SUM(bs.runs_scored + COALESCE(er.extra_runs,0)) AS runs_conceded
    FROM ball_by_ball AS b
    JOIN batsman_scored AS bs
      ON b.match_id = bs.match_id
     AND b.over_id  = bs.over_id
     AND b.ball_id  = bs.ball_id
     AND b.innings_no = bs.innings_no
    LEFT JOIN extra_runs AS er
      ON b.match_id = er.match_id
     AND b.over_id  = er.over_id
     AND b.ball_id  = er.ball_id
     AND b.innings_no = er.innings_no
    GROUP BY b.bowler
),
wickets_taken AS (
    SELECT 
        b.bowler,
        COUNT(*) AS wickets
    FROM wicket_taken AS w
    JOIN ball_by_ball AS b
      ON b.match_id = w.match_id
     AND b.over_id  = w.over_id
     AND b.ball_id  = w.ball_id
     AND b.innings_no = w.innings_no
    WHERE w.kind_out <> 'run out'
    GROUP BY b.bowler
)
SELECT 
    p.player_name,
    ROUND(1.0 * r.runs_conceded / w.wickets, 2) AS bowling_average
FROM runs_conceded AS r
JOIN wickets_taken AS w   ON r.bowler = w.bowler
JOIN player         AS p   ON p.player_id = r.bowler
WHERE w.wickets > 0
ORDER BY bowling_average ASC
LIMIT 1;