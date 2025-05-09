WITH
/* ---------- 1.  Most frequent role for every player ---------- */
role_counts AS (
    SELECT
        pm.player_id,
        pm.role,
        COUNT(*)                                    AS cnt
    FROM   player_match pm
    GROUP  BY pm.player_id, pm.role
),
most_role AS (
    SELECT player_id,
           role AS most_frequent_role
    FROM  (
        SELECT
            player_id,
            role,
            cnt,
            ROW_NUMBER() OVER (PARTITION BY player_id
                               ORDER BY cnt DESC , role) AS rn
        FROM role_counts
    )
    WHERE rn = 1
),
/* ---------- 2.  Batting aggregates ---------- */
total_runs AS (
    SELECT bb.striker AS player_id,
           SUM(bs.runs_scored)                     AS total_runs
    FROM   batsman_scored bs
    JOIN   ball_by_ball  bb
           ON bb.match_id = bs.match_id
          AND bb.over_id  = bs.over_id
          AND bb.ball_id  = bs.ball_id
    GROUP  BY bb.striker
),
balls_faced AS (
    SELECT striker AS player_id,
           COUNT(*)                               AS balls_faced
    FROM   ball_by_ball
    GROUP  BY striker
),
dismissals AS (
    SELECT player_out AS player_id,
           COUNT(*)                               AS dismissals
    FROM   wicket_taken
    GROUP  BY player_out
),
matches_played AS (
    SELECT player_id,
           COUNT(DISTINCT match_id)               AS matches_played
    FROM   player_match
    GROUP  BY player_id
),
runs_per_match AS (
    SELECT bb.striker AS player_id,
           bs.match_id,
           SUM(bs.runs_scored)                    AS runs_in_match
    FROM   batsman_scored bs
    JOIN   ball_by_ball  bb
           ON bb.match_id = bs.match_id
          AND bb.over_id  = bs.over_id
          AND bb.ball_id  = bs.ball_id
    GROUP  BY bb.striker, bs.match_id
),
highest_score AS (
    SELECT player_id,
           MAX(runs_in_match)                     AS highest_score
    FROM   runs_per_match
    GROUP  BY player_id
),
matches_30 AS (
    SELECT player_id,
           COUNT(*)                               AS matches_30
    FROM   runs_per_match
    WHERE  runs_in_match >= 30
    GROUP  BY player_id
),
matches_50 AS (
    SELECT player_id,
           COUNT(*)                               AS matches_50
    FROM   runs_per_match
    WHERE  runs_in_match >= 50
    GROUP  BY player_id
),
matches_100 AS (
    SELECT player_id,
           COUNT(*)                               AS matches_100
    FROM   runs_per_match
    WHERE  runs_in_match >= 100
    GROUP  BY player_id
),
/* ---------- 3.  Bowling aggregates ---------- */
total_wkts AS (
    SELECT bb.bowler AS player_id,
           COUNT(*)                               AS wickets_taken
    FROM   wicket_taken wt
    JOIN   ball_by_ball bb
           ON bb.match_id = wt.match_id
          AND bb.over_id  = wt.over_id
          AND bb.ball_id  = wt.ball_id
    GROUP  BY bb.bowler
),
bowler_figures AS (
    SELECT bb.bowler AS player_id,
           COUNT(*)                               AS balls_bowled,
           SUM(bs.runs_scored)                    AS runs_conceded
    FROM   ball_by_ball  bb
    JOIN   batsman_scored bs
           ON bs.match_id = bb.match_id
          AND bs.over_id  = bb.over_id
          AND bs.ball_id  = bb.ball_id
    GROUP  BY bb.bowler
),
economy_rate AS (
    SELECT player_id,
           CASE
               WHEN balls_bowled = 0 THEN NULL
               ELSE (1.0 * runs_conceded) / (balls_bowled / 6.0)
           END                                    AS economy
    FROM   bowler_figures
),
bowling_per_match AS (
    SELECT
        bb.bowler                                AS player_id,
        wt.match_id,
        COUNT(*)                                 AS wickets_in_match,
        SUM(bs.runs_scored)                      AS runs_conceded_in_match
    FROM   wicket_taken wt
    JOIN   ball_by_ball  bb
           ON bb.match_id = wt.match_id
          AND bb.over_id  = wt.over_id
          AND bb.ball_id  = wt.ball_id
    LEFT  JOIN batsman_scored bs
           ON bs.match_id = bb.match_id
          AND bs.over_id  = bb.over_id
          AND bs.ball_id  = bb.ball_id
    GROUP  BY bb.bowler, wt.match_id
),
best_bowling AS (
    SELECT player_id,
           wickets_in_match,
           runs_conceded_in_match,
           wickets_in_match || '-' || runs_conceded_in_match AS best_bowling
    FROM (
        SELECT
            player_id,
            wickets_in_match,
            runs_conceded_in_match,
            ROW_NUMBER() OVER (PARTITION BY player_id
                               ORDER BY wickets_in_match DESC ,
                                        runs_conceded_in_match ASC) AS rn
        FROM bowling_per_match
    )
    WHERE rn = 1
)
/* ---------- 4.  Final result ---------- */
SELECT
       p.player_id,
       p.player_name,
       COALESCE(most_role.most_frequent_role, '')               AS most_frequent_role,
       p.batting_hand,
       p.bowling_skill,
       COALESCE(total_runs.total_runs, 0)                       AS total_runs,
       COALESCE(matches_played.matches_played, 0)               AS matches_played,
       COALESCE(dismissals.dismissals, 0)                       AS dismissals,
       CASE
           WHEN COALESCE(dismissals.dismissals,0) = 0 THEN NULL
           ELSE ROUND(1.0 * total_runs.total_runs / dismissals.dismissals, 4)
       END                                                      AS batting_average,
       COALESCE(highest_score.highest_score, 0)                 AS highest_score,
       COALESCE(matches_30.matches_30, 0)                       AS matches_30_plus,
       COALESCE(matches_50.matches_50, 0)                       AS matches_50_plus,
       COALESCE(matches_100.matches_100, 0)                     AS matches_100_plus,
       COALESCE(balls_faced.balls_faced, 0)                     AS balls_faced,
       CASE
           WHEN COALESCE(balls_faced.balls_faced,0) = 0 THEN NULL
           ELSE ROUND(100.0 * total_runs.total_runs / balls_faced.balls_faced, 4)
       END                                                      AS strike_rate,
       COALESCE(total_wkts.wickets_taken, 0)                    AS total_wickets,
       ROUND(economy_rate.economy, 4)                           AS economy_rate,
       best_bowling.best_bowling
FROM   player              p
LEFT  JOIN most_role        ON most_role.player_id       = p.player_id
LEFT  JOIN total_runs       ON total_runs.player_id      = p.player_id
LEFT  JOIN matches_played   ON matches_played.player_id  = p.player_id
LEFT  JOIN dismissals       ON dismissals.player_id      = p.player_id
LEFT  JOIN highest_score    ON highest_score.player_id   = p.player_id
LEFT  JOIN matches_30       ON matches_30.player_id      = p.player_id
LEFT  JOIN matches_50       ON matches_50.player_id      = p.player_id
LEFT  JOIN matches_100      ON matches_100.player_id     = p.player_id
LEFT  JOIN balls_faced      ON balls_faced.player_id     = p.player_id
LEFT  JOIN total_wkts       ON total_wkts.player_id      = p.player_id
LEFT  JOIN economy_rate     ON economy_rate.player_id    = p.player_id
LEFT  JOIN best_bowling     ON best_bowling.player_id    = p.player_id
ORDER BY p.player_id;