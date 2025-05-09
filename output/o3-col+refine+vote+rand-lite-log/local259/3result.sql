WITH
-- 1. most–frequent role for every player
role_cnt AS (
    SELECT player_id ,
           role ,
           COUNT(*) AS c
    FROM   player_match
    GROUP  BY player_id , role
),
role_rank AS (
    SELECT player_id ,
           role ,
           ROW_NUMBER() OVER (PARTITION BY player_id
                              ORDER BY c DESC , role) AS rn
    FROM   role_cnt
),
most_role AS (
    SELECT player_id ,
           role AS most_frequent_role
    FROM   role_rank
    WHERE  rn = 1
),

/*------------------------------------------------------------------
  2.  Batting – all deliveries that came off the bat
------------------------------------------------------------------*/
ball_bat AS (
    SELECT b.striker        AS player_id ,
           b.match_id ,
           bs.runs_scored
    FROM   ball_by_ball  b
    JOIN   batsman_scored bs
           ON  b.match_id   = bs.match_id
           AND b.over_id    = bs.over_id
           AND b.ball_id    = bs.ball_id
           AND b.innings_no = bs.innings_no
),
bat_tot AS (                              -- career aggregates
    SELECT player_id ,
           SUM(runs_scored) AS total_runs ,
           COUNT(*)         AS balls_faced
    FROM   ball_bat
    GROUP  BY player_id
),
bat_match AS (                            -- runs per match
    SELECT player_id ,
           match_id ,
           SUM(runs_scored) AS runs_in_match
    FROM   ball_bat
    GROUP  BY player_id , match_id
),
bat_extra AS (                            -- high score & 30/50/100 counts
    SELECT player_id ,
           MAX(runs_in_match)                                                   AS highest_score ,
           SUM(CASE WHEN runs_in_match >= 30  THEN 1 ELSE 0 END)                AS matches_30_plus ,
           SUM(CASE WHEN runs_in_match >= 50  THEN 1 ELSE 0 END)                AS matches_50_plus ,
           SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END)                AS matches_100_plus
    FROM   bat_match
    GROUP  BY player_id
),

/*------------------------------------------------------------------
  3.  Dismissals
------------------------------------------------------------------*/
dismiss AS (
    SELECT player_out AS player_id ,
           COUNT(*)   AS dismissals
    FROM   wicket_taken
    GROUP  BY player_out
),

/*------------------------------------------------------------------
  4.  Matches played (from player-match table)
------------------------------------------------------------------*/
matches_played AS (
    SELECT player_id ,
           COUNT(DISTINCT match_id) AS total_matches
    FROM   player_match
    GROUP  BY player_id
),

/*------------------------------------------------------------------
  5.  Bowling aggregates
------------------------------------------------------------------*/
ball_bowl AS (
    SELECT b.bowler        AS player_id ,
           b.match_id ,
           bs.runs_scored
    FROM   ball_by_ball  b
    JOIN   batsman_scored bs
           ON  b.match_id   = bs.match_id
           AND b.over_id    = bs.over_id
           AND b.ball_id    = bs.ball_id
           AND b.innings_no = bs.innings_no
),
bowl_tot AS (                             -- career runs conceded / balls bowled
    SELECT player_id ,
           SUM(runs_scored) AS runs_conceded ,
           COUNT(*)         AS balls_bowled
    FROM   ball_bowl
    GROUP  BY player_id
),
wkt_tot AS (                              -- career wickets
    SELECT b.bowler AS player_id ,
           COUNT(*)  AS wickets_taken
    FROM   wicket_taken w
    JOIN   ball_by_ball b
           ON  w.match_id   = b.match_id
           AND w.over_id    = b.over_id
           AND w.ball_id    = b.ball_id
           AND w.innings_no = b.innings_no
    GROUP  BY b.bowler
),

/*------------------------------------------------------------------
  6.  Best bowling figure (most wickets, then least runs)
------------------------------------------------------------------*/
per_match_bowl AS (
    SELECT b.bowler AS player_id ,
           b.match_id ,
           COUNT(w.player_out)                    AS wkts ,
           SUM(bs.runs_scored)                    AS runs
    FROM   ball_by_ball  b
    JOIN   batsman_scored bs
           ON  b.match_id   = bs.match_id
           AND b.over_id    = bs.over_id
           AND b.ball_id    = bs.ball_id
           AND b.innings_no = bs.innings_no
    LEFT  JOIN wicket_taken w
           ON  w.match_id   = b.match_id
           AND w.over_id    = b.over_id
           AND w.ball_id    = b.ball_id
           AND w.innings_no = b.innings_no
    GROUP  BY b.bowler , b.match_id
),
best_bowl_rank AS (
    SELECT player_id ,
           wkts ,
           runs ,
           ROW_NUMBER() OVER (PARTITION BY player_id
                              ORDER BY wkts DESC , runs ASC) AS rn
    FROM   per_match_bowl
),
best_bowl AS (
    SELECT player_id ,
           printf('%d-%d', wkts, runs) AS best_bowling
    FROM   best_bowl_rank
    WHERE  rn = 1
)

/*------------------------------------------------------------------
  7.  Final output
------------------------------------------------------------------*/
SELECT
       p.player_id ,
       p.player_name ,
       COALESCE(mr.most_frequent_role,'')                          AS most_frequent_role ,
       p.batting_hand ,
       p.bowling_skill ,
       COALESCE(bt.total_runs,0)                                   AS total_runs ,
       COALESCE(mp.total_matches,0)                                AS matches_played ,
       COALESCE(d.dismissals,0)                                    AS dismissals ,
       CASE WHEN d.dismissals>0
            THEN ROUND(bt.total_runs*1.0/d.dismissals,4)
       END                                                         AS batting_average ,
       COALESCE(be.highest_score,0)                                AS highest_score ,
       COALESCE(be.matches_30_plus,0)                              AS matches_30_plus ,
       COALESCE(be.matches_50_plus,0)                              AS matches_50_plus ,
       COALESCE(be.matches_100_plus,0)                             AS matches_100_plus ,
       COALESCE(bt.balls_faced,0)                                  AS balls_faced ,
       CASE WHEN bt.balls_faced>0
            THEN ROUND(bt.total_runs*100.0/bt.balls_faced,4)
       END                                                         AS strike_rate ,
       COALESCE(wk.wickets_taken,0)                                AS wickets_taken ,
       CASE WHEN bo.balls_bowled>0
            THEN ROUND(bo.runs_conceded*6.0/bo.balls_bowled,4)
       END                                                         AS economy_rate ,
       bb.best_bowling                                             AS best_bowling_performance
FROM   player              p
LEFT  JOIN most_role       mr ON mr.player_id = p.player_id
LEFT  JOIN bat_tot         bt ON bt.player_id = p.player_id
LEFT  JOIN bat_extra       be ON be.player_id = p.player_id
LEFT  JOIN dismiss         d  ON d.player_id  = p.player_id
LEFT  JOIN matches_played  mp ON mp.player_id = p.player_id
LEFT  JOIN bowl_tot        bo ON bo.player_id = p.player_id
LEFT  JOIN wkt_tot         wk ON wk.player_id = p.player_id
LEFT  JOIN best_bowl       bb ON bb.player_id = p.player_id
ORDER BY p.player_id;