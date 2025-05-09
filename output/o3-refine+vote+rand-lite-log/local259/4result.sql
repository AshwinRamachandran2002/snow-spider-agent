WITH
---------------------------------------------------------------------
-- 1.  Most–frequent role for every player
---------------------------------------------------------------------
player_roles AS (
    SELECT player_id ,
           role ,
           COUNT(*) AS cnt
    FROM   player_match
    GROUP  BY player_id , role
),
most_role AS (
    SELECT player_id ,
           role
    FROM   (
              SELECT player_id ,
                     role ,
                     cnt ,
                     ROW_NUMBER() OVER (PARTITION BY player_id
                                        ORDER BY cnt DESC , role) AS rn
              FROM   player_roles
           )
    WHERE  rn = 1
),
---------------------------------------------------------------------
-- 2.  Number of matches played by every player
---------------------------------------------------------------------
matches_played AS (
    SELECT player_id ,
           COUNT(DISTINCT match_id) AS matches_played
    FROM   player_match
    GROUP  BY player_id
),
---------------------------------------------------------------------
-- 3.  Batting –‑ runs & balls faced PER MATCH
---------------------------------------------------------------------
bat_runs AS (
    SELECT b.striker              AS player_id ,
           b.match_id             ,
           SUM(s.runs_scored)     AS runs_scored ,
           COUNT(*)               AS balls_faced
    FROM   batsman_scored AS s
    JOIN   ball_by_ball   AS b
           USING (match_id , over_id , ball_id)
    GROUP  BY player_id , b.match_id
),
---------------------------------------------------------------------
-- 4.  Batting –‑ career aggregates
---------------------------------------------------------------------
bat_agg AS (
    SELECT player_id ,
           SUM(runs_scored)                               AS total_runs ,
           SUM(balls_faced)                              AS total_balls ,
           MAX(runs_scored)                              AS highest_score ,
           SUM(CASE WHEN runs_scored >= 30 THEN 1 ELSE 0 END) AS matches_30 ,
           SUM(CASE WHEN runs_scored >= 50 THEN 1 ELSE 0 END) AS matches_50 ,
           SUM(CASE WHEN runs_scored >=100 THEN 1 ELSE 0 END) AS matches_100
    FROM   bat_runs
    GROUP  BY player_id
),
---------------------------------------------------------------------
-- 5.  Times dismissed
---------------------------------------------------------------------
dismissals AS (
    SELECT player_out AS player_id ,
           COUNT(*)   AS dismissals
    FROM   wicket_taken
    GROUP  BY player_out
),
---------------------------------------------------------------------
-- 6.  Bowling –‑ runs conceded & balls bowled PER MATCH
---------------------------------------------------------------------
bowling_per_ball AS (
    SELECT b.bowler             AS player_id ,
           b.match_id           ,
           COALESCE(s.runs_scored , 0) AS runs_scored
    FROM   ball_by_ball  AS b
    LEFT   JOIN batsman_scored AS s
           USING (match_id , over_id , ball_id)
),
bowling_runs AS (
    SELECT player_id ,
           match_id ,
           SUM(runs_scored) AS runs_conceded ,
           COUNT(*)         AS balls_bowled
    FROM   bowling_per_ball
    GROUP  BY player_id , match_id
),
---------------------------------------------------------------------
-- 7.  Bowling –‑ wickets PER MATCH
---------------------------------------------------------------------
wickets_match AS (
    SELECT b.bowler  AS player_id ,
           b.match_id,
           COUNT(*)   AS wickets
    FROM   wicket_taken AS w
    JOIN   ball_by_ball AS b
           ON  w.match_id = b.match_id
           AND w.over_id  = b.over_id
           AND w.ball_id  = b.ball_id
    GROUP  BY player_id , b.match_id
),
---------------------------------------------------------------------
-- 8.  Bowling –‑ join runs & wickets PER MATCH
---------------------------------------------------------------------
bowling_match AS (
    SELECT br.player_id ,
           br.match_id ,
           br.runs_conceded ,
           br.balls_bowled ,
           COALESCE(wm.wickets , 0) AS wickets
    FROM   bowling_runs  AS br
    LEFT   JOIN wickets_match AS wm
           ON  br.player_id = wm.player_id
           AND br.match_id  = wm.match_id
),
---------------------------------------------------------------------
-- 9.  Bowling –‑ career aggregates
---------------------------------------------------------------------
bowling_agg AS (
    SELECT player_id ,
           SUM(runs_conceded)  AS runs_conceded_tot ,
           SUM(balls_bowled)   AS balls_bowled_tot ,
           SUM(wickets)        AS wickets_tot
    FROM   bowling_match
    GROUP  BY player_id
),
---------------------------------------------------------------------
-- 10. Best bowling figure (wickets‑runs) per player
---------------------------------------------------------------------
best_bowling AS (
    SELECT player_id ,
           wickets ,
           runs_conceded ,
           ROW_NUMBER() OVER (PARTITION BY player_id
                              ORDER BY wickets DESC ,
                                       runs_conceded ASC) AS rn
    FROM   bowling_match
),
best_bowling_pick AS (
    SELECT player_id ,
           printf('%d-%d', wickets , runs_conceded) AS best_fig
    FROM   best_bowling
    WHERE  rn = 1
)
---------------------------------------------------------------------
-- 11. Final result
---------------------------------------------------------------------
SELECT  p.player_id ,
        p.player_name ,
        COALESCE(mr.role , '')                         AS most_frequent_role ,
        p.batting_hand ,
        p.bowling_skill ,
        COALESCE(ba.total_runs , 0)                    AS total_runs ,
        COALESCE(mp.matches_played , 0)                AS total_matches ,
        COALESCE(d.dismissals , 0)                     AS total_dismissals ,
        CASE WHEN COALESCE(d.dismissals , 0) > 0
             THEN ROUND(ba.total_runs * 1.0 / d.dismissals , 4)
        END                                            AS batting_average ,
        COALESCE(ba.highest_score , 0)                 AS highest_score ,
        COALESCE(ba.matches_30 , 0)                    AS matches_30_plus ,
        COALESCE(ba.matches_50 , 0)                    AS matches_50_plus ,
        COALESCE(ba.matches_100 , 0)                   AS matches_100_plus ,
        COALESCE(ba.total_balls , 0)                   AS balls_faced ,
        CASE WHEN COALESCE(ba.total_balls , 0) > 0
             THEN ROUND(ba.total_runs * 100.0 / ba.total_balls , 4)
        END                                            AS strike_rate ,
        COALESCE(bg.wickets_tot , 0)                   AS total_wickets ,
        CASE WHEN COALESCE(bg.balls_bowled_tot , 0) > 0
             THEN ROUND(bg.runs_conceded_tot * 6.0 / bg.balls_bowled_tot , 4)
        END                                            AS economy_rate ,
        COALESCE(bb.best_fig , '')                     AS best_bowling
FROM    player               AS p
LEFT    JOIN most_role        AS mr  USING (player_id)
LEFT    JOIN matches_played   AS mp  USING (player_id)
LEFT    JOIN bat_agg          AS ba  ON p.player_id = ba.player_id
LEFT    JOIN dismissals       AS d   ON p.player_id = d.player_id
LEFT    JOIN bowling_agg      AS bg  ON p.player_id = bg.player_id
LEFT    JOIN best_bowling_pick AS bb ON p.player_id = bb.player_id
ORDER BY p.player_id;