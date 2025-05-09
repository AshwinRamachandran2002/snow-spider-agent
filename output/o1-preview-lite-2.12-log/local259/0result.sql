WITH
most_frequent_role AS (
    SELECT r1.player_id, r1.role
    FROM (
        SELECT player_id, role, COUNT(*) AS role_count
        FROM player_match
        GROUP BY player_id, role
    ) r1
    JOIN (
        SELECT player_id, MAX(role_count) AS max_role_count
        FROM (
            SELECT player_id, role, COUNT(*) AS role_count
            FROM player_match
            GROUP BY player_id, role
        ) r2
        GROUP BY player_id
    ) r2 ON r1.player_id = r2.player_id AND r1.role_count = r2.max_role_count
),
total_runs_scored AS (
    SELECT b.striker AS player_id, SUM(bs.runs_scored) AS total_runs_scored
    FROM batsman_scored bs
    JOIN ball_by_ball b
      ON bs.match_id = b.match_id AND
         bs.over_id = b.over_id AND
         bs.ball_id = b.ball_id AND
         bs.innings_no = b.innings_no
    GROUP BY b.striker
),
total_balls_faced AS (
    SELECT b.striker AS player_id, COUNT(*) AS total_balls_faced
    FROM ball_by_ball b
    GROUP BY b.striker
),
total_dismissals AS (
    SELECT player_out AS player_id, COUNT(*) AS total_dismissals
    FROM wicket_taken
    GROUP BY player_out
),
total_matches_played AS (
    SELECT player_id, COUNT(DISTINCT match_id) AS total_matches_played
    FROM player_match
    GROUP BY player_id
),
highest_scores AS (
    SELECT striker AS player_id, MAX(total_runs) AS highest_score_in_single_match
    FROM (
      SELECT b.striker AS striker, b.match_id, SUM(bs.runs_scored) AS total_runs
      FROM batsman_scored bs
      JOIN ball_by_ball b
        ON bs.match_id = b.match_id AND
           bs.over_id = b.over_id AND
           bs.ball_id = b.ball_id AND
           bs.innings_no = b.innings_no
      GROUP BY b.striker, b.match_id
    ) scores_per_match
    GROUP BY striker
),
matches_scored_over AS (
    SELECT striker AS player_id,
      COUNT(CASE WHEN total_runs > 30 THEN 1 END) AS number_of_matches_scored_over_30,
      COUNT(CASE WHEN total_runs > 50 THEN 1 END) AS number_of_matches_scored_over_50,
      COUNT(CASE WHEN total_runs > 100 THEN 1 END) AS number_of_matches_scored_over_100
    FROM (
      SELECT b.striker AS striker, b.match_id, SUM(bs.runs_scored) AS total_runs
      FROM batsman_scored bs
      JOIN ball_by_ball b
        ON bs.match_id = b.match_id AND
           bs.over_id = b.over_id AND
           bs.ball_id = b.ball_id AND
           bs.innings_no = b.innings_no
      GROUP BY b.striker, b.match_id
    ) scores_per_match
    GROUP BY striker
),
total_wickets_taken AS (
    SELECT b.bowler AS player_id, COUNT(*) AS total_wickets_taken
    FROM ball_by_ball b
    JOIN wicket_taken w
      ON b.match_id = w.match_id AND
         b.over_id = w.over_id AND
         b.ball_id = w.ball_id AND
         b.innings_no = w.innings_no
    GROUP BY b.bowler
),
total_runs_conceded AS (
    SELECT b.bowler AS player_id, SUM(bs.runs_scored) AS total_runs_conceded
    FROM ball_by_ball b
    JOIN batsman_scored bs
      ON b.match_id = bs.match_id AND
         b.over_id = bs.over_id AND
         b.ball_id = bs.ball_id AND
         b.innings_no = bs.innings_no
    GROUP BY b.bowler
),
total_balls_bowled AS (
    SELECT b.bowler AS player_id, COUNT(*) AS total_balls_bowled
    FROM ball_by_ball b
    GROUP BY b.bowler
),
bowling_performance_per_match AS (
    SELECT b.bowler AS player_id, b.match_id,
        COUNT(w.player_out) AS wickets_taken,
        SUM(COALESCE(bs.runs_scored, 0)) AS runs_conceded
    FROM ball_by_ball b
    LEFT JOIN wicket_taken w
      ON b.match_id = w.match_id AND
         b.over_id = w.over_id AND
         b.ball_id = w.ball_id AND
         b.innings_no = w.innings_no
    LEFT JOIN batsman_scored bs
      ON b.match_id = bs.match_id AND
         b.over_id = bs.over_id AND
         b.ball_id = bs.ball_id AND
         bs.innings_no = b.innings_no
    WHERE b.bowler IS NOT NULL
    GROUP BY b.bowler, b.match_id
),
best_bowling_performance AS (
    SELECT t1.player_id,
        t1.wickets_taken || '-' || t1.runs_conceded AS best_bowling_performance
    FROM bowling_performance_per_match t1
    WHERE t1.wickets_taken = (
        SELECT MAX(wickets_taken)
        FROM bowling_performance_per_match t2
        WHERE t2.player_id = t1.player_id
    )
    AND t1.runs_conceded = (
        SELECT MIN(runs_conceded)
        FROM bowling_performance_per_match t3
        WHERE t3.player_id = t1.player_id AND t3.wickets_taken = t1.wickets_taken
    )
    GROUP BY t1.player_id
)

SELECT
    p.player_id,
    p.player_name,
    COALESCE(mfr.role, 'Player') AS most_frequent_role,
    p.batting_hand,
    p.bowling_skill,
    COALESCE(trs.total_runs_scored, 0) AS total_runs_scored,
    COALESCE(tmp.total_matches_played, 0) AS total_matches_played,
    COALESCE(td.total_dismissals, 0) AS total_dismissals,
    CASE WHEN COALESCE(td.total_dismissals, 0) > 0 THEN ROUND(COALESCE(trs.total_runs_scored, 0) * 1.0 / td.total_dismissals, 4) ELSE NULL END AS batting_average,
    hs.highest_score_in_single_match,
    COALESCE(mso.number_of_matches_scored_over_30, 0) AS number_of_matches_scored_over_30,
    COALESCE(mso.number_of_matches_scored_over_50, 0) AS number_of_matches_scored_over_50,
    COALESCE(mso.number_of_matches_scored_over_100, 0) AS number_of_matches_scored_over_100,
    COALESCE(tbf.total_balls_faced, 0) AS total_balls_faced,
    CASE WHEN COALESCE(tbf.total_balls_faced, 0) > 0 THEN ROUND(COALESCE(trs.total_runs_scored, 0) * 100.0 / tbf.total_balls_faced, 4) ELSE NULL END AS strike_rate,
    COALESCE(twt.total_wickets_taken, 0) AS total_wickets_taken,
    CASE WHEN COALESCE(tbb.total_balls_bowled, 0) > 0 THEN ROUND(COALESCE(trc.total_runs_conceded, 0) * 6.0 / tbb.total_balls_bowled, 4) ELSE NULL END AS economy_rate,
    bbp.best_bowling_performance
FROM player p
LEFT JOIN most_frequent_role mfr ON p.player_id = mfr.player_id
LEFT JOIN total_runs_scored trs ON p.player_id = trs.player_id
LEFT JOIN total_matches_played tmp ON p.player_id = tmp.player_id
LEFT JOIN total_dismissals td ON p.player_id = td.player_id
LEFT JOIN highest_scores hs ON p.player_id = hs.player_id
LEFT JOIN matches_scored_over mso ON p.player_id = mso.player_id
LEFT JOIN total_balls_faced tbf ON p.player_id = tbf.player_id
LEFT JOIN total_wickets_taken twt ON p.player_id = twt.player_id
LEFT JOIN total_runs_conceded trc ON p.player_id = trc.player_id
LEFT JOIN total_balls_bowled tbb ON p.player_id = tbb.player_id
LEFT JOIN best_bowling_performance bbp ON p.player_id = bbp.player_id
ORDER BY p.player_id;