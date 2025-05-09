SELECT p.player_name AS Bowler_name,
       ROUND(rc.total_runs_conceded * 1.0 / wt.total_wickets, 4) AS Bowling_average
FROM (
    SELECT b.bowler,
           SUM(
               COALESCE(bs.runs_scored, 0) +
               CASE WHEN er.extra_type IN ('no ball', 'wides') THEN COALESCE(er.extra_runs, 0) ELSE 0 END
           ) AS total_runs_conceded
    FROM ball_by_ball b
    LEFT JOIN batsman_scored bs ON b.match_id = bs.match_id
        AND b.over_id = bs.over_id
        AND b.ball_id = bs.ball_id
        AND b.innings_no = bs.innings_no
    LEFT JOIN extra_runs er ON b.match_id = er.match_id
        AND b.over_id = er.over_id
        AND b.ball_id = er.ball_id
        AND b.innings_no = er.innings_no
    GROUP BY b.bowler
) rc
JOIN (
    SELECT b.bowler, COUNT(*) AS total_wickets
    FROM ball_by_ball b
    JOIN wicket_taken w ON b.match_id = w.match_id
        AND b.over_id = w.over_id
        AND b.ball_id = w.ball_id
        AND b.innings_no = w.innings_no
    WHERE w.kind_out != 'run out' AND w.kind_out IS NOT NULL
    GROUP BY b.bowler
) wt ON rc.bowler = wt.bowler
JOIN player p ON rc.bowler = p.player_id
WHERE rc.total_runs_conceded > 0 AND wt.total_wickets > 0
ORDER BY Bowling_average ASC
LIMIT 1;