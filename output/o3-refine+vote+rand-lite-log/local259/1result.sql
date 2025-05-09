WITH ball AS (                /* every legal delivery with the runs scored off the bat */
    SELECT  bb.match_id ,
            bb.over_id ,
            bb.ball_id ,
            bb.innings_no ,
            bb.striker ,
            bb.bowler ,
            COALESCE(bs.runs_scored ,0) AS runs_batsman
    FROM    ball_by_ball  bb
    LEFT JOIN batsman_scored bs
           ON bs.match_id   = bb.match_id
          AND bs.over_id    = bb.over_id
          AND bs.ball_id    = bb.ball_id
          AND bs.innings_no = bb.innings_no
),
/* --------------  BATSMAN STATISTICS  ---------------- */
batting_match AS (            /* runs & balls for every player‑match */
    SELECT  striker               AS player_id ,
            match_id ,
            SUM(runs_batsman)     AS runs ,
            COUNT(*)              AS balls
    FROM    ball
    GROUP BY striker , match_id
),
batting_overall AS (          /* career‑level batting aggregates */
    SELECT  player_id ,
            SUM(runs)                              AS total_runs ,
            SUM(balls)                             AS total_balls ,
            MAX(runs)                              AS highest_score ,
            SUM(CASE WHEN runs>=30  THEN 1 END)    AS inns_30 ,
            SUM(CASE WHEN runs>=50  THEN 1 END)    AS inns_50 ,
            SUM(CASE WHEN runs>=100 THEN 1 END)    AS inns_100
    FROM    batting_match
    GROUP BY player_id
),
dismissals AS (               /* number of times out */
    SELECT  player_out AS player_id ,
            COUNT(*)    AS total_dismissals
    FROM    wicket_taken
    GROUP BY player_out
),
/* --------------  BOWLING STATISTICS  ---------------- */
bowling_ball AS (             /* every ball bowled by each bowler */
    SELECT  b.match_id ,
            b.bowler                 AS player_id ,
            b.runs_batsman           ,
            CASE WHEN wt.player_out IS NULL THEN 0 ELSE 1 END AS is_wicket
    FROM    ball b
    LEFT JOIN wicket_taken wt
           ON wt.match_id   = b.match_id
          AND wt.over_id    = b.over_id
          AND wt.ball_id    = b.ball_id
          AND wt.innings_no = b.innings_no
),
bowling_match AS (            /* per match bowling figures */
    SELECT  player_id ,
            match_id ,
            SUM(runs_batsman) AS runs_conceded ,
            SUM(is_wicket)    AS wickets ,
            COUNT(*)          AS balls
    FROM    bowling_ball
    GROUP BY player_id , match_id
),
bowling_overall AS (          /* career aggregates with economy rate */
    SELECT  player_id ,
            SUM(runs_conceded)          AS runs_conceded ,
            SUM(wickets)                AS wickets ,
            SUM(balls)                  AS balls_bowled
    FROM    bowling_match
    GROUP BY player_id
),
economy AS (
    SELECT  player_id ,
            wickets                    AS total_wickets ,
            runs_conceded              AS runs_conceded ,
            balls_bowled               AS balls_bowled ,
            CASE WHEN balls_bowled>0
                 THEN ROUND(runs_conceded*6.0/balls_bowled ,4)
            END                       AS economy_rate
    FROM    bowling_overall
),
best_bowl_rank AS (           /* rank bowling performances – most wkts, then least runs */
    SELECT  player_id ,
            wickets ,
            runs_conceded ,
            ROW_NUMBER() OVER (PARTITION BY player_id
                               ORDER BY wickets DESC , runs_conceded ASC) AS rn
    FROM    bowling_match
),
best_bowl AS (                /* take only the best (rn = 1) */
    SELECT  player_id ,
            wickets || '-' || runs_conceded AS best_figures
    FROM    best_bowl_rank
    WHERE   rn = 1
),
/* --------------  MISCELLANEOUS  ---------------- */
matches_played AS (
    SELECT  player_id ,
            COUNT(DISTINCT match_id) AS matches_played
    FROM    player_match
    GROUP BY player_id
),
role_mode AS (                /* most frequent role (mode) */
    SELECT  player_id ,
            role
    FROM   (
        SELECT  player_id ,
                role ,
                COUNT(*)                           AS cnt ,
                ROW_NUMBER() OVER (PARTITION BY player_id
                                   ORDER BY COUNT(*) DESC , role) AS rn
        FROM    player_match
        GROUP BY player_id , role
    )
    WHERE   rn = 1
)
/* --------------  FINAL RESULT  ---------------- */
SELECT  p.player_id ,
        p.player_name ,
        rm.role                                AS most_frequent_role ,
        p.batting_hand ,
        p.bowling_skill ,

        COALESCE(bo.total_runs  ,0)            AS total_runs_scored ,
        COALESCE(mp.matches_played ,0)         AS total_matches_played ,
        COALESCE(d.total_dismissals ,0)        AS total_times_dismissed ,
        CASE WHEN d.total_dismissals>0
             THEN ROUND(bo.total_runs*1.0/d.total_dismissals ,4)
        END                                    AS batting_average ,
        COALESCE(bo.highest_score ,0)          AS highest_score ,
        COALESCE(bo.inns_30 ,0)                AS matches_30_plus ,
        COALESCE(bo.inns_50 ,0)                AS matches_50_plus ,
        COALESCE(bo.inns_100,0)                AS matches_100_plus ,
        COALESCE(bo.total_balls ,0)            AS total_balls_faced ,
        CASE WHEN bo.total_balls>0
             THEN ROUND(bo.total_runs*100.0/bo.total_balls ,4)
        END                                    AS strike_rate ,

        COALESCE(e.total_wickets ,0)           AS total_wickets_taken ,
        e.economy_rate                         AS economy_rate ,
        bb.best_figures                        AS best_bowling_figures
FROM    player p
LEFT JOIN role_mode     rm ON rm.player_id = p.player_id
LEFT JOIN batting_overall bo ON bo.player_id = p.player_id
LEFT JOIN matches_played mp ON mp.player_id = p.player_id
LEFT JOIN dismissals    d  ON d.player_id  = p.player_id
LEFT JOIN economy       e  ON e.player_id  = p.player_id
LEFT JOIN best_bowl     bb ON bb.player_id = p.player_id;