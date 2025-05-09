WITH
-- Player basic info
player_info AS (
    SELECT player_id, player_name, batting_hand, bowling_skill
    FROM player
),
-- Most frequent role
player_role AS (
    SELECT player_id, role,
        ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY COUNT(*) DESC) AS rn
    FROM player_match
    GROUP BY player_id, role
),
most_frequent_role AS (
    SELECT player_id, role AS most_frequent_role
    FROM player_role
    WHERE rn = 1
),
-- Total runs scored per player
total_runs AS (
    SELECT bb.striker AS player_id, SUM(bs.runs_scored) AS total_runs_scored
    FROM ball_by_ball bb
    JOIN batsman_scored bs USING (match_id, over_id, ball_id, innings_no)
    GROUP BY bb.striker
),
-- Total matches played per player
total_matches AS (
    SELECT player_id, COUNT(DISTINCT match_id) AS total_matches_played
    FROM player_match
    GROUP BY player_id
),
-- Total dismissals per player
total_dismissals AS (
    SELECT player_out AS player_id, COUNT(*) AS total_dismissals
    FROM wicket_taken
    GROUP BY player_out
),
-- Highest score in a single match per player
highest_score_per_match AS (
    SELECT bb.striker AS player_id, bb.match_id, SUM(bs.runs_scored) AS total_runs
    FROM ball_by_ball bb
    JOIN batsman_scored bs USING (match_id, over_id, ball_id, innings_no)
    GROUP BY bb.striker, bb.match_id
),
highest_score AS (
    SELECT player_id, MAX(total_runs) AS highest_score_in_single_match
    FROM highest_score_per_match
    GROUP BY player_id
),
-- Number of matches where score over 30
matches_scored_over_30 AS (
    SELECT player_id, COUNT(*) AS matches_scored_over_30
    FROM (
        SELECT bb.striker AS player_id, bb.match_id, SUM(bs.runs_scored) AS total_runs
        FROM ball_by_ball bb
        JOIN batsman_scored bs USING (match_id, over_id, ball_id, innings_no)
        GROUP BY bb.striker, bb.match_id
        HAVING SUM(bs.runs_scored) > 30
    ) t
    GROUP BY player_id
),
-- Number of matches where score over 50
matches_scored_over_50 AS (
    SELECT player_id, COUNT(*) AS matches_scored_over_50
    FROM (
        SELECT bb.striker AS player_id, bb.match_id, SUM(bs.runs_scored) AS total_runs
        FROM ball_by_ball bb
        JOIN batsman_scored bs USING (match_id, over_id, ball_id, innings_no)
        GROUP BY bb.striker, bb.match_id
        HAVING SUM(bs.runs_scored) > 50
    ) t
    GROUP BY player_id
),
-- Number of matches where score over 100
matches_scored_over_100 AS (
    SELECT player_id, COUNT(*) AS matches_scored_over_100
    FROM (
        SELECT bb.striker AS player_id, bb.match_id, SUM(bs.runs_scored) AS total_runs
        FROM ball_by_ball bb
        JOIN batsman_scored bs USING (match_id, over_id, ball_id, innings_no)
        GROUP BY bb.striker, bb.match_id
        HAVING SUM(bs.runs_scored) > 100
    ) t
    GROUP BY player_id
),
-- Total balls faced per player
total_balls_faced AS (
    SELECT striker AS player_id, COUNT(*) AS total_balls_faced
    FROM ball_by_ball
    GROUP BY striker
),
-- Strike rate per player
strike_rate AS (
    SELECT tr.player_id,
           CASE WHEN tbf.total_balls_faced > 0
                THEN (tr.total_runs_scored * 100.0) / tbf.total_balls_faced
                ELSE 0 END AS strike_rate
    FROM total_runs tr
    JOIN total_balls_faced tbf ON tr.player_id = tbf.player_id
),
-- Total wickets taken per player
total_wickets_taken AS (
    SELECT bb.bowler AS player_id, COUNT(*) AS total_wickets_taken
    FROM wicket_taken wt
    JOIN ball_by_ball bb USING (match_id, over_id, ball_id, innings_no)
    GROUP BY bb.bowler
),
-- Total runs conceded per bowler
total_runs_conceded AS (
    SELECT bb.bowler AS player_id, SUM(bs.runs_scored) AS total_runs_conceded
    FROM ball_by_ball bb
    JOIN batsman_scored bs USING (match_id, over_id, ball_id, innings_no)
    GROUP BY bb.bowler
),
-- Total overs bowled per bowler
total_overs_bowled AS (
    SELECT bowler AS player_id, COUNT(DISTINCT match_id || '-' || innings_no || '-' || over_id) AS overs_bowled
    FROM ball_by_ball
    GROUP BY bowler
),
-- Economy rate per bowler
economy_rate AS (
    SELECT trc.player_id,
           CASE WHEN tob.overs_bowled > 0
                THEN trc.total_runs_conceded * 1.0 / tob.overs_bowled
                ELSE 0 END AS economy_rate
    FROM total_runs_conceded trc
    JOIN total_overs_bowled tob ON trc.player_id = tob.player_id
),
-- Best bowling performance per bowler
best_bowling_performance AS (
    SELECT player_id, best_wickets_taken, best_runs_given
    FROM (
        SELECT player_id, best_wickets_taken, best_runs_given,
               ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY best_wickets_taken DESC, best_runs_given ASC) AS rn
        FROM (
            SELECT bb.bowler AS player_id,
                   COUNT(*) AS best_wickets_taken,
                   SUM(bs.runs_scored) AS best_runs_given
            FROM wicket_taken wt
            JOIN ball_by_ball bb USING (match_id, over_id, ball_id, innings_no)
            JOIN batsman_scored bs USING (match_id, over_id, ball_id, innings_no)
            GROUP BY bb.bowler, bb.match_id
        )
    )
    WHERE rn = 1
)

SELECT
    pi.player_id,
    pi.player_name,
    COALESCE(mfr.most_frequent_role, 'Player') AS most_frequent_role,
    pi.batting_hand,
    pi.bowling_skill,
    COALESCE(tr.total_runs_scored, 0) AS total_runs_scored,
    COALESCE(tm.total_matches_played, 0) AS total_matches_played,
    COALESCE(td.total_dismissals, 0) AS total_dismissals,
    ROUND(CASE WHEN COALESCE(td.total_dismissals, 0) > 0 
         THEN tr.total_runs_scored * 1.0 / td.total_dismissals
         ELSE tr.total_runs_scored END, 4) AS batting_average,
    COALESCE(hs.highest_score_in_single_match, 0) AS highest_score_in_single_match,
    COALESCE(ms30.matches_scored_over_30, 0) AS number_of_matches_scored_over_30,
    COALESCE(ms50.matches_scored_over_50, 0) AS number_of_matches_scored_over_50,
    COALESCE(ms100.matches_scored_over_100, 0) AS number_of_matches_scored_over_100,
    COALESCE(tbf.total_balls_faced, 0) AS total_balls_faced,
    ROUND(COALESCE(sr.strike_rate, 0), 4) AS strike_rate,
    COALESCE(tw.total_wickets_taken, 0) AS total_wickets_taken,
    ROUND(COALESCE(er.economy_rate, 0), 4) AS economy_rate,
    CASE WHEN bbp.best_wickets_taken IS NOT NULL
         THEN bbp.best_wickets_taken || '-' || bbp.best_runs_given
         ELSE NULL END AS best_bowling_performance
FROM player_info pi
LEFT JOIN most_frequent_role mfr ON pi.player_id = mfr.player_id
LEFT JOIN total_runs tr ON pi.player_id = tr.player_id
LEFT JOIN total_matches tm ON pi.player_id = tm.player_id
LEFT JOIN total_dismissals td ON pi.player_id = td.player_id
LEFT JOIN highest_score hs ON pi.player_id = hs.player_id
LEFT JOIN matches_scored_over_30 ms30 ON pi.player_id = ms30.player_id
LEFT JOIN matches_scored_over_50 ms50 ON pi.player_id = ms50.player_id
LEFT JOIN matches_scored_over_100 ms100 ON pi.player_id = ms100.player_id
LEFT JOIN total_balls_faced tbf ON pi.player_id = tbf.player_id
LEFT JOIN strike_rate sr ON pi.player_id = sr.player_id
LEFT JOIN total_wickets_taken tw ON pi.player_id = tw.player_id
LEFT JOIN economy_rate er ON pi.player_id = er.player_id
LEFT JOIN best_bowling_performance bbp ON pi.player_id = bbp.player_id
ORDER BY pi.player_id
LIMIT 100;