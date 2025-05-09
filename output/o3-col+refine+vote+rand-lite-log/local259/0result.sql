WITH
player_basic AS (
    SELECT p.player_id,
           p.player_name,
           p.batting_hand,
           p.bowling_skill
    FROM   player p
),

-- most-frequent role of a player
role_cte AS (
    SELECT player_id,
           role
    FROM  (
        SELECT player_id,
               role,
               COUNT(*)                                        AS cnt,
               ROW_NUMBER() OVER (PARTITION BY player_id
                                   ORDER BY COUNT(*) DESC, role) AS rn
        FROM   player_match
        GROUP  BY player_id, role
    )
    WHERE  rn = 1
),

-- matches appeared
matches_played AS (
    SELECT player_id,
           COUNT(DISTINCT match_id) AS matches_played
    FROM   player_match
    GROUP  BY player_id
),

-- every legal delivery faced by a batsman
batting_per_ball AS (
    SELECT bb.striker  AS player_id,
           bs.runs_scored
    FROM   ball_by_ball  bb
    JOIN   batsman_scored bs
           ON  bb.match_id   = bs.match_id
           AND bb.over_id    = bs.over_id
           AND bb.ball_id    = bs.ball_id
           AND bb.innings_no = bs.innings_no
),

batting_totals AS (
    SELECT player_id,
           SUM(runs_scored)        AS total_runs,
           COUNT(*)                AS balls_faced
    FROM   batting_per_ball
    GROUP  BY player_id
),

-- dismissals
dismissals AS (
    SELECT player_out AS player_id,
           COUNT(*)   AS times_out
    FROM   wicket_taken
    GROUP  BY player_out
),

-- runs by a batsman in each match
batting_match AS (
    SELECT bb.striker AS player_id,
           bb.match_id,
           SUM(bs.runs_scored) AS runs_in_match
    FROM   ball_by_ball  bb
    JOIN   batsman_scored bs
           ON  bb.match_id   = bs.match_id
           AND bb.over_id    = bs.over_id
           AND bb.ball_id    = bs.ball_id
           AND bb.innings_no = bs.innings_no
    GROUP  BY bb.striker, bb.match_id
),

batting_match_agg AS (
    SELECT player_id,
           MAX(runs_in_match)                                           AS highest_score,
           SUM(CASE WHEN runs_in_match >= 30  THEN 1 ELSE 0 END)        AS thirties,
           SUM(CASE WHEN runs_in_match >= 50  THEN 1 ELSE 0 END)        AS fifties,
           SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END)        AS hundreds
    FROM   batting_match
    GROUP  BY player_id
),

-- bowling: balls bowled, runs conceded, wickets
bowling_balls AS (
    SELECT bb.bowler AS player_id,
           COUNT(*)  AS balls_bowled
    FROM   ball_by_ball bb
    GROUP  BY bb.bowler
),

bowling_runs AS (
    SELECT bb.bowler AS player_id,
           SUM(bs.runs_scored) AS runs_conceded
    FROM   ball_by_ball  bb
    JOIN   batsman_scored bs
           ON  bb.match_id   = bs.match_id
           AND bb.over_id    = bs.over_id
           AND bb.ball_id    = bs.ball_id
           AND bb.innings_no = bs.innings_no
    GROUP  BY bb.bowler
),

wickets_taken AS (
    SELECT bb.bowler AS player_id,
           COUNT(*)  AS wickets
    FROM   wicket_taken wt
    JOIN   ball_by_ball bb
           ON  wt.match_id   = bb.match_id
           AND wt.over_id    = bb.over_id
           AND wt.ball_id    = bb.ball_id
           AND wt.innings_no = bb.innings_no
    GROUP  BY bb.bowler
),

-- bowling figures per match (needed for “best bowling”)
bowler_match_stats AS (
    SELECT bb.bowler AS player_id,
           bb.match_id,
           SUM(bs.runs_scored)                                            AS runs_conceded,
           SUM(CASE WHEN wt.player_out IS NOT NULL THEN 1 ELSE 0 END)     AS wickets
    FROM   ball_by_ball  bb
    JOIN   batsman_scored bs
           ON  bb.match_id   = bs.match_id
           AND bb.over_id    = bs.over_id
           AND bb.ball_id    = bs.ball_id
           AND bb.innings_no = bs.innings_no
    LEFT  JOIN wicket_taken wt
           ON  wt.match_id   = bb.match_id
           AND wt.over_id    = bb.over_id
           AND wt.ball_id    = bb.ball_id
           AND wt.innings_no = bb.innings_no
    GROUP  BY bb.bowler, bb.match_id
),

best_bowling_pick AS (
    SELECT player_id,
           wickets,
           runs_conceded,
           ROW_NUMBER() OVER (PARTITION BY player_id
                              ORDER BY wickets DESC, runs_conceded ASC) AS rn
    FROM   bowler_match_stats
),

best_bowling AS (
    SELECT player_id,
           CASE WHEN wickets IS NULL
                THEN NULL
                ELSE CAST(wickets AS TEXT) || '-' || CAST(runs_conceded AS TEXT)
           END AS best_figures
    FROM   best_bowling_pick
    WHERE  rn = 1
),

-- economy rate
economy AS (
    SELECT b.player_id,
           ROUND( (COALESCE(r.runs_conceded,0) * 6.0) / b.balls_bowled , 4) AS economy_rate
    FROM   bowling_balls b
    LEFT  JOIN bowling_runs r USING (player_id)
)

SELECT
    pb.player_id,
    pb.player_name,
    COALESCE(rc.role , 'Unknown')                         AS most_frequent_role,
    pb.batting_hand,
    pb.bowling_skill,
    COALESCE(bt.total_runs , 0)                           AS total_runs,
    COALESCE(mp.matches_played , 0)                       AS matches_played,
    COALESCE(d.times_out , 0)                             AS times_out,
    CASE WHEN COALESCE(d.times_out , 0) > 0
         THEN ROUND( bt.total_runs * 1.0 / d.times_out , 4)
    END                                                   AS batting_average,
    COALESCE(bma.highest_score , 0)                       AS highest_score,
    COALESCE(bma.thirties , 0)                            AS matches_30_plus,
    COALESCE(bma.fifties , 0)                             AS matches_50_plus,
    COALESCE(bma.hundreds , 0)                            AS matches_100_plus,
    COALESCE(bt.balls_faced , 0)                          AS balls_faced,
    CASE WHEN COALESCE(bt.balls_faced , 0) > 0
         THEN ROUND( bt.total_runs * 100.0 / bt.balls_faced , 4)
    END                                                   AS strike_rate,
    COALESCE(wt.wickets , 0)                              AS total_wickets,
    economy.economy_rate,
    best_bowling.best_figures                             AS best_bowling
FROM   player_basic pb
LEFT  JOIN role_cte           rc  USING (player_id)
LEFT  JOIN batting_totals     bt  USING (player_id)
LEFT  JOIN matches_played     mp  USING (player_id)
LEFT  JOIN dismissals         d   USING (player_id)
LEFT  JOIN batting_match_agg  bma USING (player_id)
LEFT  JOIN wickets_taken      wt  USING (player_id)
LEFT  JOIN economy            USING (player_id)
LEFT  JOIN best_bowling       USING (player_id)
ORDER BY pb.player_id;