WITH
/* 1.  Most–frequent role of every player */
pm_role AS (
    SELECT
        player_id,
        role,
        COUNT(*)                              AS cnt,
        ROW_NUMBER() OVER (PARTITION BY player_id
                           ORDER BY COUNT(*) DESC , role) AS rn
    FROM player_match
    GROUP BY player_id , role
),
most_role AS (
    SELECT player_id ,
           role  AS most_frequent_role
    FROM   pm_role
    WHERE  rn = 1
),

/* 2.  Number of matches played by every player */
matches_played AS (
    SELECT player_id ,
           COUNT(DISTINCT match_id) AS total_matches
    FROM   player_match
    GROUP  BY player_id
),

/* 3.  Pure batting, ball‑by‑ball – total runs & balls faced            */
batting_stats AS (
    SELECT
        bb.striker                       AS player_id,
        SUM(bs.runs_scored)              AS total_runs,
        COUNT(*)                         AS balls_faced
    FROM   ball_by_ball  bb
    JOIN   batsman_scored bs
           ON  bb.match_id    = bs.match_id
           AND bb.over_id     = bs.over_id
           AND bb.ball_id     = bs.ball_id
           AND bb.innings_no  = bs.innings_no
    GROUP  BY bb.striker
),

/* 4.  Times dismissed */
dismissals AS (
    SELECT player_out AS player_id ,
           COUNT(*)   AS total_dismissals
    FROM   wicket_taken
    GROUP  BY player_out
),

/* 5.  Runs per (player,match) to derive 30/50/100 & highest score */
runs_per_match AS (
    SELECT
        bb.striker              AS player_id,
        bb.match_id,
        SUM(bs.runs_scored)     AS runs_in_match
    FROM   ball_by_ball  bb
    JOIN   batsman_scored bs
           ON  bb.match_id    = bs.match_id
           AND bb.over_id     = bs.over_id
           AND bb.ball_id     = bs.ball_id
           AND bb.innings_no  = bs.innings_no
    GROUP  BY bb.striker , bb.match_id
),
batting_derived AS (
    SELECT
        player_id,
        MAX(runs_in_match)                                             AS highest_score,
        SUM(CASE WHEN runs_in_match >=  30 THEN 1 ELSE 0 END)          AS matches_30plus,
        SUM(CASE WHEN runs_in_match >=  50 THEN 1 ELSE 0 END)          AS matches_50plus,
        SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END)          AS matches_100plus
    FROM   runs_per_match
    GROUP  BY player_id
),

/* 6.  Bowling – balls bowled & runs conceded (extras ignored) */
bowling_base AS (
    SELECT
        bb.bowler                  AS player_id,
        COUNT(*)                   AS balls_bowled,
        SUM(bs.runs_scored)        AS runs_conceded
    FROM   ball_by_ball  bb
    JOIN   batsman_scored bs
           ON  bb.match_id    = bs.match_id
           AND bb.over_id     = bs.over_id
           AND bb.ball_id     = bs.ball_id
           AND bb.innings_no  = bs.innings_no
    GROUP  BY bb.bowler
),

/* 7.  Wickets credited to the bowler                                     */
wickets_by_bowler AS (
    SELECT
        bb.bowler      AS player_id,
        COUNT(*)       AS wickets_taken
    FROM   wicket_taken wt
    JOIN   ball_by_ball bb
           ON wt.match_id   = bb.match_id
          AND wt.over_id    = bb.over_id
          AND wt.ball_id    = bb.ball_id
          AND wt.innings_no = bb.innings_no
    GROUP  BY bb.bowler
),

/* 8.  Bowling figures per match to obtain “best” performance              */
bowling_per_match AS (
    SELECT
        bb.bowler                                AS player_id,
        bb.match_id,
        COUNT(wt.player_out)                     AS wickets_in_match,
        SUM(bs.runs_scored)                      AS runs_conceded_in_match
    FROM   ball_by_ball bb
    LEFT  JOIN wicket_taken wt
           ON  wt.match_id   = bb.match_id
           AND wt.over_id    = bb.over_id
           AND wt.ball_id    = bb.ball_id
           AND wt.innings_no = bb.innings_no
    JOIN   batsman_scored bs
           ON  bb.match_id   = bs.match_id
           AND bb.over_id    = bs.over_id
           AND bb.ball_id    = bs.ball_id
           AND bb.innings_no = bs.innings_no
    GROUP  BY bb.bowler , bb.match_id
),
best_bowling AS (
    SELECT player_id ,
           wickets_in_match ,
           runs_conceded_in_match
    FROM  (
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

/* 9.  Final projection                                                    */
SELECT
    p.player_id,
    p.player_name,
    COALESCE(most_role.most_frequent_role,'N/A')                 AS most_frequent_role,
    p.batting_hand,
    p.bowling_skill,

    /* Batting */
    COALESCE(batting_stats.total_runs ,0)                        AS total_runs_scored,
    COALESCE(matches_played.total_matches ,0)                    AS total_matches_played,
    COALESCE(dismissals.total_dismissals ,0)                     AS total_times_dismissed,
    CASE WHEN COALESCE(dismissals.total_dismissals ,0) > 0
         THEN ROUND(1.0 * COALESCE(batting_stats.total_runs ,0)
                    / dismissals.total_dismissals,4)
         ELSE NULL END                                           AS batting_average,
    COALESCE(batting_derived.highest_score ,0)                   AS highest_score,
    COALESCE(batting_derived.matches_30plus ,0)                  AS matches_30plus,
    COALESCE(batting_derived.matches_50plus ,0)                  AS matches_50plus,
    COALESCE(batting_derived.matches_100plus ,0)                 AS matches_100plus,
    COALESCE(batting_stats.balls_faced ,0)                       AS total_balls_faced,
    CASE WHEN COALESCE(batting_stats.balls_faced ,0) > 0
         THEN ROUND(100.0 * COALESCE(batting_stats.total_runs ,0)
                    / batting_stats.balls_faced ,4)
         ELSE NULL END                                           AS strike_rate,

    /* Bowling */
    COALESCE(wickets_by_bowler.wickets_taken ,0)                 AS total_wickets_taken,
    CASE WHEN COALESCE(bowling_base.balls_bowled ,0) > 0
         THEN ROUND(6.0 * COALESCE(bowling_base.runs_conceded ,0)
                    / bowling_base.balls_bowled ,4)
         ELSE NULL END                                           AS economy_rate,
    CASE WHEN best_bowling.wickets_in_match IS NOT NULL
         THEN CAST(best_bowling.wickets_in_match AS TEXT)
              || '-' ||
              CAST(best_bowling.runs_conceded_in_match AS TEXT)
         ELSE NULL END                                           AS best_bowling_figures
FROM   player p
LEFT  JOIN most_role          ON p.player_id = most_role.player_id
LEFT  JOIN matches_played     ON p.player_id = matches_played.player_id
LEFT  JOIN batting_stats      ON p.player_id = batting_stats.player_id
LEFT  JOIN dismissals         ON p.player_id = dismissals.player_id
LEFT  JOIN batting_derived    ON p.player_id = batting_derived.player_id
LEFT  JOIN wickets_by_bowler  ON p.player_id = wickets_by_bowler.player_id
LEFT  JOIN bowling_base       ON p.player_id = bowling_base.player_id
LEFT  JOIN best_bowling       ON p.player_id = best_bowling.player_id
ORDER BY p.player_id;