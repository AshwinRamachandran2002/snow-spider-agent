WITH
total_runs AS (
    SELECT b."striker" AS player_id, SUM(s."runs_scored") AS total_runs_scored
    FROM "ball_by_ball" AS b
    JOIN "batsman_scored" AS s
      ON b."match_id" = s."match_id" AND b."over_id" = s."over_id"
     AND b."ball_id" = s."ball_id" AND b."innings_no" = s."innings_no"
    GROUP BY b."striker"
),
total_balls_faced AS (
    SELECT "striker" AS player_id, COUNT(*) AS total_balls_faced
    FROM "ball_by_ball"
    GROUP BY "striker"
),
total_matches AS (
    SELECT "player_id", COUNT(DISTINCT "match_id") AS total_matches_played
    FROM "player_match"
    GROUP BY "player_id"
),
total_dismissals AS (
    SELECT "player_out" AS player_id, COUNT(*) AS total_dismissals
    FROM "wicket_taken"
    GROUP BY "player_out"
),
most_frequent_role AS (
    SELECT pm."player_id", pm."role"
    FROM (
        SELECT "player_id", "role", COUNT(*) AS role_count,
               ROW_NUMBER() OVER (PARTITION BY "player_id" ORDER BY COUNT(*) DESC) AS rn
        FROM "player_match"
        GROUP BY "player_id", "role"
    ) pm
    WHERE pm.rn = 1
),
player_match_runs AS (
    SELECT b."striker" AS player_id, b."match_id", SUM(s."runs_scored") AS runs_in_match
    FROM "ball_by_ball" AS b
    JOIN "batsman_scored" AS s
      ON b."match_id" = s."match_id" AND b."over_id" = s."over_id"
     AND b."ball_id" = s."ball_id" AND b."innings_no" = s."innings_no"
    GROUP BY b."striker", b."match_id"
),
highest_score AS (
    SELECT player_id, MAX(runs_in_match) AS highest_score_in_single_match
    FROM player_match_runs
    GROUP BY player_id
),
matches_over_scores AS (
    SELECT player_id,
           SUM(CASE WHEN runs_in_match > 30 THEN 1 ELSE 0 END) AS number_of_matches_scored_over_30,
           SUM(CASE WHEN runs_in_match > 50 THEN 1 ELSE 0 END) AS number_of_matches_scored_over_50,
           SUM(CASE WHEN runs_in_match > 100 THEN 1 ELSE 0 END) AS number_of_matches_scored_over_100
    FROM player_match_runs
    GROUP BY player_id
),
total_wickets AS (
    SELECT b."bowler" AS player_id, COUNT(*) AS total_wickets_taken
    FROM "ball_by_ball" AS b
    JOIN "wicket_taken" AS w
      ON b."match_id" = w."match_id" AND b."over_id" = w."over_id"
     AND b."ball_id" = w."ball_id" AND b."innings_no" = w."innings_no"
    WHERE b."bowler" IS NOT NULL
    GROUP BY b."bowler"
),
bowling_stats AS (
    SELECT b."bowler" AS player_id,
           SUM(s."runs_scored") AS runs_conceded,
           COUNT(*) AS balls_bowled
    FROM "ball_by_ball" AS b
    JOIN "batsman_scored" AS s
      ON b."match_id" = s."match_id" AND b."over_id" = s."over_id"
     AND b."ball_id" = s."ball_id" AND b."innings_no" = s."innings_no"
    GROUP BY b."bowler"
),
best_bowling_performance AS (
    SELECT player_id, MAX(wickets_in_match) AS max_wickets
    FROM (
        SELECT b."bowler" AS player_id, b."match_id", COUNT(w."player_out") AS wickets_in_match
        FROM "ball_by_ball" AS b
        LEFT JOIN "wicket_taken" AS w
          ON b."match_id" = w."match_id" AND b."over_id" = w."over_id"
         AND b."ball_id" = w."ball_id" AND b."innings_no" = w."innings_no"
        WHERE b."bowler" IS NOT NULL
        GROUP BY b."bowler", b."match_id"
    ) sub
    GROUP BY player_id
),
best_bowling_detail AS (
    SELECT t.player_id, t.wickets_in_match, t.runs_conceded_in_match
    FROM (
        SELECT b."bowler" AS player_id, b."match_id", COUNT(w."player_out") AS wickets_in_match, SUM(s."runs_scored") AS runs_conceded_in_match
        FROM "ball_by_ball" AS b
        LEFT JOIN "wicket_taken" AS w
          ON b."match_id" = w."match_id" AND b."over_id" = w."over_id"
         AND b."ball_id" = w."ball_id" AND b."innings_no" = w."innings_no"
        LEFT JOIN "batsman_scored" AS s
          ON b."match_id" = s."match_id" AND b."over_id" = s."over_id"
         AND b."ball_id" = s."ball_id" AND b."innings_no" = s."innings_no"
        WHERE b."bowler" IS NOT NULL
        GROUP BY b."bowler", b."match_id"
    ) t
    INNER JOIN best_bowling_performance bbp ON t.player_id = bbp.player_id AND t.wickets_in_match = bbp.max_wickets
    ORDER BY t.player_id, t.wickets_in_match DESC, t.runs_conceded_in_match
),
best_performance AS (
    SELECT player_id, wickets_in_match, runs_conceded_in_match
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY player_id ORDER BY wickets_in_match DESC, runs_conceded_in_match ASC) AS rn
        FROM best_bowling_detail
    ) WHERE rn = 1
)
SELECT
    p."player_id",
    p."player_name",
    mfr."role" AS most_frequent_role,
    p."batting_hand",
    p."bowling_skill",
    tr.total_runs_scored,
    tm.total_matches_played,
    td.total_dismissals,
    ROUND(CASE WHEN td.total_dismissals > 0 THEN (tr.total_runs_scored * 1.0 / td.total_dismissals) ELSE NULL END, 4) AS batting_average,
    hs.highest_score_in_single_match,
    mos.number_of_matches_scored_over_30,
    mos.number_of_matches_scored_over_50,
    mos.number_of_matches_scored_over_100,
    tbf.total_balls_faced,
    ROUND(CASE WHEN tbf.total_balls_faced > 0 THEN (tr.total_runs_scored * 100.0 / tbf.total_balls_faced) ELSE NULL END, 4) AS strike_rate,
    tw.total_wickets_taken,
    ROUND(CASE WHEN bs.balls_bowled > 0 THEN (bs.runs_conceded * 6.0 / bs.balls_bowled) ELSE NULL END, 4) AS economy_rate,
    COALESCE(bp.wickets_in_match || '-' || bp.runs_conceded_in_match, NULL) AS best_bowling_performance
FROM
    "player" AS p
LEFT JOIN most_frequent_role AS mfr ON p."player_id" = mfr."player_id"
LEFT JOIN total_runs AS tr ON p."player_id" = tr.player_id
LEFT JOIN total_matches AS tm ON p."player_id" = tm."player_id"
LEFT JOIN total_dismissals AS td ON p."player_id" = td.player_id
LEFT JOIN highest_score AS hs ON p."player_id" = hs.player_id
LEFT JOIN matches_over_scores AS mos ON p."player_id" = mos.player_id
LEFT JOIN total_balls_faced AS tbf ON p."player_id" = tbf.player_id
LEFT JOIN total_wickets AS tw ON p."player_id" = tw.player_id
LEFT JOIN bowling_stats AS bs ON p."player_id" = bs.player_id
LEFT JOIN best_performance AS bp ON p."player_id" = bp.player_id
ORDER BY p."player_id";