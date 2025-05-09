WITH 
    per_bowler AS (
        SELECT bb.bowler,
            COUNT(*) AS total_balls,
            SUM(bs.runs_scored) AS total_runs_conceded,
            COUNT(wt.player_out) AS total_wickets,
            (SUM(bs.runs_scored) * 6.0)/COUNT(*) AS economy_rate,
            CASE WHEN COUNT(wt.player_out) > 0 THEN (COUNT(*) * 1.0)/COUNT(wt.player_out) ELSE NULL END AS strike_rate
        FROM ball_by_ball bb
        JOIN batsman_scored bs 
            ON bb.match_id = bs.match_id 
            AND bb.over_id = bs.over_id 
            AND bb.ball_id = bs.ball_id 
            AND bb.innings_no = bs.innings_no
        LEFT JOIN wicket_taken wt 
            ON bb.match_id = wt.match_id 
            AND bb.over_id = wt.over_id 
            AND bb.ball_id = wt.ball_id 
            AND bb.innings_no = wt.innings_no
        GROUP BY bb.bowler
    ),
    per_bowler_per_match AS (
        SELECT bb.bowler,
            bb.match_id,
            SUM(bs.runs_scored) AS runs_conceded_in_match,
            COUNT(wt.player_out) AS wickets_in_match
        FROM ball_by_ball bb
        JOIN batsman_scored bs 
            ON bb.match_id = bs.match_id 
            AND bb.over_id = bs.over_id 
            AND bb.ball_id = bs.ball_id 
            AND bb.innings_no = bs.innings_no
        LEFT JOIN wicket_taken wt 
            ON bb.match_id = wt.match_id 
            AND bb.over_id = wt.over_id 
            AND bb.ball_id = wt.ball_id 
            AND bb.innings_no = wt.innings_no
        GROUP BY bb.bowler, bb.match_id
    ),
    max_wickets_per_bowler AS (
        SELECT
            bowler,
            MAX(wickets_in_match) AS max_wickets
        FROM per_bowler_per_match
        GROUP BY bowler
    ),
    min_runs_per_bowler AS (
        SELECT
            pbpm.bowler,
            pbpm.wickets_in_match,
            MIN(pbpm.runs_conceded_in_match) AS min_runs
        FROM per_bowler_per_match pbpm
        JOIN max_wickets_per_bowler mwpb
            ON pbpm.bowler = mwpb.bowler AND pbpm.wickets_in_match = mwpb.max_wickets
        GROUP BY pbpm.bowler
    ),
    best_performance_candidates AS (
        SELECT pbpm.bowler, pbpm.match_id, pbpm.wickets_in_match, pbpm.runs_conceded_in_match
        FROM per_bowler_per_match pbpm
        JOIN min_runs_per_bowler mrpb
            ON pbpm.bowler = mrpb.bowler AND pbpm.wickets_in_match = mrpb.wickets_in_match AND pbpm.runs_conceded_in_match = mrpb.min_runs
    ),
    best_performance AS (
        SELECT
            bpc.bowler,
            bpc.match_id,
            bpc.wickets_in_match,
            bpc.runs_conceded_in_match
        FROM best_performance_candidates bpc
        WHERE bpc.match_id = (
                SELECT MIN(match_id)
                FROM best_performance_candidates bpc2
                WHERE bpc2.bowler = bpc.bowler
            )
    )
SELECT
    p.player_name AS bowler_name,
    per_bowler.total_wickets,
    ROUND(per_bowler.economy_rate, 4) AS economy_rate,
    ROUND(per_bowler.strike_rate, 4) AS strike_rate,
    printf('%d-%d', best_performance.wickets_in_match, best_performance.runs_conceded_in_match) AS best_performance
FROM per_bowler
JOIN player p ON per_bowler.bowler = p.player_id
JOIN best_performance ON best_performance.bowler = per_bowler.bowler
ORDER BY p.player_name;