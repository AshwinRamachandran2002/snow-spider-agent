WITH
/*----------------- 1. player’s most frequent role -----------------*/
role_freq AS (
    SELECT  player_id ,
            role ,
            COUNT(*) AS cnt
    FROM    player_match
    GROUP BY player_id , role
),
best_role AS (
    SELECT  player_id ,
            role
    FROM   (
        SELECT  player_id ,
                role ,
                cnt ,
                ROW_NUMBER() OVER (PARTITION BY player_id 
                                   ORDER BY cnt DESC , role) AS rn
        FROM    role_freq
    )
    WHERE rn = 1
),

/*----------------- 2. join every ball with runs scored -------------*/
ball_runs AS (
    SELECT  bb.match_id ,
            bb.over_id ,
            bb.ball_id ,
            bb.innings_no ,
            bb.striker       AS batsman_id ,
            bb.bowler        AS bowler_id ,
            bs.runs_scored
    FROM    ball_by_ball  bb
    JOIN    batsman_scored bs
           ON  bs.match_id   = bb.match_id
           AND bs.over_id    = bb.over_id
           AND bs.ball_id    = bb.ball_id
           AND bs.innings_no = bb.innings_no
),

/*----------------- 3. basic batting totals ------------------------*/
batting_totals AS (
    SELECT  batsman_id            AS player_id ,
            SUM(runs_scored)      AS total_runs ,
            COUNT(*)              AS balls_faced
    FROM    ball_runs
    GROUP BY batsman_id
),

/*----------------- 4. dismissals ----------------------------------*/
dismissals AS (
    SELECT  player_out  AS player_id ,
            COUNT(*)    AS dismissals
    FROM    wicket_taken
    GROUP BY player_out
),

/*----------------- 5. per‑match batting numbers -------------------*/
match_batting AS (
    SELECT  batsman_id  AS player_id ,
            match_id ,
            SUM(runs_scored) AS runs_in_match
    FROM    ball_runs
    GROUP BY batsman_id , match_id
),
batting_extra AS (
    SELECT  player_id ,
            MAX(runs_in_match)                                           AS highest_score ,
            SUM(CASE WHEN runs_in_match >= 30  THEN 1 ELSE 0 END)        AS matches_30 ,
            SUM(CASE WHEN runs_in_match >= 50  THEN 1 ELSE 0 END)        AS matches_50 ,
            SUM(CASE WHEN runs_in_match >= 100 THEN 1 ELSE 0 END)        AS matches_100 ,
            COUNT(*)                                                     AS matches_played
    FROM    match_batting
    GROUP BY player_id
),

/*----------------- 6. wickets credited to bowler ------------------*/
ball_wickets AS (
    SELECT  bb.bowler   AS player_id ,
            wt.match_id ,
            wt.over_id ,
            wt.ball_id
    FROM    wicket_taken wt
    JOIN    ball_by_ball bb
           ON  bb.match_id   = wt.match_id
           AND bb.over_id    = wt.over_id
           AND bb.ball_id    = wt.ball_id
           AND bb.innings_no = wt.innings_no
),
bowling_totals AS (
    SELECT  player_id ,
            COUNT(*) AS total_wickets
    FROM    ball_wickets
    GROUP BY player_id
),

/*----------------- 7. runs conceded & balls bowled ----------------*/
bowling_runs_balls AS (
    SELECT  bowler_id   AS player_id ,
            SUM(runs_scored) AS runs_conceded ,
            COUNT(*)         AS balls_bowled
    FROM    ball_runs
    GROUP BY bowler_id
),

/*----------------- 8. best bowling in a match ---------------------*/
wickets_per_match AS (
    SELECT  player_id ,
            match_id ,
            COUNT(*) AS wkts_in_match
    FROM    ball_wickets
    GROUP BY player_id , match_id
),
runs_conceded_per_match AS (
    SELECT  bowler_id  AS player_id ,
            match_id ,
            SUM(runs_scored) AS runs_in_match
    FROM    ball_runs
    GROUP BY bowler_id , match_id
),
bowling_match AS (
    SELECT  w.player_id ,
            w.match_id ,
            w.wkts_in_match ,
            COALESCE(r.runs_in_match , 0) AS runs_in_match
    FROM    wickets_per_match w
    LEFT JOIN runs_conceded_per_match r
           ON  r.player_id = w.player_id
           AND r.match_id  = w.match_id
),
best_bowling AS (
    SELECT  player_id ,
            wkts_in_match ,
            runs_in_match
    FROM   (
        SELECT  player_id ,
                wkts_in_match ,
                runs_in_match ,
                ROW_NUMBER() OVER (PARTITION BY player_id
                                   ORDER BY wkts_in_match DESC ,
                                            runs_in_match ASC) AS rn
        FROM    bowling_match
    )
    WHERE rn = 1
)

/*----------------- 9. final output --------------------------------*/
SELECT
        p.player_id                              AS player_id ,
        p.player_name                            AS player_name ,
        COALESCE(br.role , 'N/A')                AS most_frequent_role ,
        p.batting_hand ,
        p.bowling_skill ,
        COALESCE(bt.total_runs , 0)              AS total_runs ,
        COALESCE(be.matches_played , 0)          AS total_matches_played ,
        COALESCE(d.dismissals , 0)               AS total_dismissals ,
        CASE WHEN COALESCE(d.dismissals , 0)=0
             THEN NULL
             ELSE ROUND(bt.total_runs*1.0 / d.dismissals , 4)
        END                                      AS batting_average ,
        COALESCE(be.highest_score , 0)           AS highest_score ,
        COALESCE(be.matches_30 , 0)              AS matches_30_plus ,
        COALESCE(be.matches_50 , 0)              AS matches_50_plus ,
        COALESCE(be.matches_100 ,0)              AS matches_100_plus ,
        COALESCE(bt.balls_faced ,0)              AS balls_faced ,
        CASE WHEN COALESCE(bt.balls_faced ,0)=0
             THEN NULL
             ELSE ROUND(bt.total_runs*100.0 / bt.balls_faced , 4)
        END                                      AS strike_rate ,
        COALESCE(bw.total_wickets ,0)            AS total_wickets ,
        CASE WHEN COALESCE(brb.balls_bowled ,0)=0
             THEN NULL
             ELSE ROUND(brb.runs_conceded*6.0 / brb.balls_bowled , 4)
        END                                      AS economy_rate ,
        CASE WHEN bb.wkts_in_match IS NULL
             THEN NULL
             ELSE CAST(bb.wkts_in_match AS TEXT) || '-' ||
                  CAST(bb.runs_in_match AS TEXT)
        END                                      AS best_bowling
FROM    player p
LEFT JOIN best_role              br  ON br.player_id = p.player_id
LEFT JOIN batting_totals         bt  ON bt.player_id = p.player_id
LEFT JOIN batting_extra          be  ON be.player_id = p.player_id
LEFT JOIN dismissals             d   ON d.player_id  = p.player_id
LEFT JOIN bowling_totals         bw  ON bw.player_id = p.player_id
LEFT JOIN bowling_runs_balls     brb ON brb.player_id= p.player_id
LEFT JOIN best_bowling           bb  ON bb.player_id = p.player_id
ORDER BY p.player_id;