/* ---------   Comprehensive career figures for every player   --------- */
WITH
/* --- every legal delivery once (extras ignored) --- */
ball_event AS (
    SELECT  b.match_id,
            b.striker,
            b.bowler,
            bs.runs_scored,
            CASE WHEN wt.player_out IS NOT NULL THEN 1 ELSE 0 END AS is_wicket
    FROM    ball_by_ball AS b
    JOIN    batsman_scored AS bs
           ON bs.match_id   = b.match_id
          AND bs.over_id    = b.over_id
          AND bs.ball_id    = b.ball_id
          AND bs.innings_no = b.innings_no
    LEFT JOIN wicket_taken AS wt
           ON wt.match_id   = b.match_id
          AND wt.over_id    = b.over_id
          AND wt.ball_id    = b.ball_id
          AND wt.innings_no = b.innings_no
),

/* -----------------------   BATTING PART   ----------------------- */
bat_match AS (
    SELECT  striker        AS player_id,
            match_id,
            SUM(runs_scored)  AS runs_scored,
            COUNT(*)          AS balls_faced
    FROM    ball_event
    GROUP  BY striker, match_id
),
bat_agg AS (
    SELECT  player_id,
            SUM(runs_scored)                                                AS total_runs,
            SUM(balls_faced)                                                AS total_balls,
            MAX(runs_scored)                                                AS highest_score,
            SUM(CASE WHEN runs_scored >= 30  THEN 1 ELSE 0 END)             AS matches_30_plus,
            SUM(CASE WHEN runs_scored >= 50  THEN 1 ELSE 0 END)             AS matches_50_plus,
            SUM(CASE WHEN runs_scored >= 100 THEN 1 ELSE 0 END)             AS matches_100_plus
    FROM    bat_match
    GROUP  BY player_id
),

/* -----------------------   BOWLING PART   ----------------------- */
bowl_match AS (
    SELECT  bowler          AS player_id,
            match_id,
            SUM(runs_scored) AS runs_conceded,
            COUNT(*)         AS balls_bowled,
            SUM(is_wicket)   AS wickets
    FROM    ball_event
    GROUP  BY bowler, match_id
),
bowl_agg AS (
    SELECT  player_id,
            SUM(wickets)          AS total_wickets,
            SUM(runs_conceded)    AS total_runs_conceded,
            SUM(balls_bowled)     AS total_balls_bowled
    FROM    bowl_match
    GROUP  BY player_id
),
best_bowl_rank AS (
    SELECT  player_id,
            wickets,
            runs_conceded,
            ROW_NUMBER() OVER (PARTITION BY player_id
                               ORDER BY wickets DESC, runs_conceded ASC) AS rn
    FROM    bowl_match
),
best_bowl AS (
    SELECT  player_id,
            printf('%d-%d', wickets, runs_conceded) AS best_bowling
    FROM    best_bowl_rank
    WHERE   rn = 1
),

/* -----------------------   OTHER HELPERS   ----------------------- */
player_matches AS (
    SELECT  player_id,
            COUNT(DISTINCT match_id) AS matches_played
    FROM    player_match
    GROUP  BY player_id
),
dismissals AS (
    SELECT  player_out AS player_id,
            COUNT(*)   AS dismissals
    FROM    wicket_taken
    GROUP  BY player_out
),
role_cnt AS (                       /* count each role occurrences */
    SELECT  player_id, role, COUNT(*) AS cnt
    FROM    player_match
    GROUP  BY player_id, role
),
role_rank AS (                      /* rank roles per player */
    SELECT  player_id,
            role,
            ROW_NUMBER() OVER (PARTITION BY player_id
                               ORDER BY cnt DESC, role) AS rn
    FROM    role_cnt
),
most_role AS (
    SELECT  player_id, role AS most_freq_role
    FROM    role_rank
    WHERE   rn = 1
)

/* -----------------------   FINAL SELECT   ----------------------- */
SELECT  p.player_id,
        p.player_name,
        COALESCE(most_role.most_freq_role, '')                        AS most_freq_role,
        p.batting_hand,
        p.bowling_skill,

        /* batting summary */
        COALESCE(bat_agg.total_runs, 0)                               AS total_runs,
        COALESCE(player_matches.matches_played, 0)                    AS matches_played,
        COALESCE(dismissals.dismissals, 0)                            AS dismissals,
        CASE WHEN COALESCE(dismissals.dismissals, 0) > 0
             THEN ROUND(1.0 * bat_agg.total_runs /
                        dismissals.dismissals, 4)
             ELSE NULL END                                            AS batting_average,
        COALESCE(bat_agg.highest_score, 0)                            AS highest_score,
        COALESCE(bat_agg.matches_30_plus, 0)                          AS matches_30_plus,
        COALESCE(bat_agg.matches_50_plus, 0)                          AS matches_50_plus,
        COALESCE(bat_agg.matches_100_plus, 0)                         AS matches_100_plus,
        COALESCE(bat_agg.total_balls, 0)                              AS total_balls_faced,
        CASE WHEN COALESCE(bat_agg.total_balls, 0) > 0
             THEN ROUND(100.0 * bat_agg.total_runs /
                        bat_agg.total_balls, 4)
             ELSE NULL END                                            AS strike_rate,

        /* bowling summary */
        COALESCE(bowl_agg.total_wickets, 0)                           AS total_wickets,
        CASE WHEN COALESCE(bowl_agg.total_balls_bowled, 0) > 0
             THEN ROUND(6.0 * bowl_agg.total_runs_conceded /
                        bowl_agg.total_balls_bowled, 4)
             ELSE NULL END                                            AS economy_rate,
        COALESCE(best_bowl.best_bowling, '')                          AS best_bowling
FROM    player              AS p
LEFT JOIN bat_agg           ON bat_agg.player_id        = p.player_id
LEFT JOIN player_matches    ON player_matches.player_id = p.player_id
LEFT JOIN dismissals        ON dismissals.player_id     = p.player_id
LEFT JOIN bowl_agg          ON bowl_agg.player_id       = p.player_id
LEFT JOIN best_bowl         ON best_bowl.player_id      = p.player_id
LEFT JOIN most_role         ON most_role.player_id      = p.player_id
ORDER BY p.player_id;