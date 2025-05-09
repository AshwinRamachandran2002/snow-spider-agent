WITH ball_details AS (
    /* 1.  Collect every ball with the two batsmen who were on the crease
          together and the runs that came from that ball                */
    SELECT
        b.match_id,
        b.innings_no,
        b.striker,
        b.non_striker,
        -- order the two batsmen so the pair is identified uniquely
        MIN(b.striker , b.non_striker) AS player_low ,
        MAX(b.striker , b.non_striker) AS player_high,
        
        COALESCE(bs.runs_scored ,0)                           AS batsman_runs,
        COALESCE(er.extra_runs ,0)                            AS extra_runs
    FROM ball_by_ball  AS b
    LEFT JOIN batsman_scored AS bs
           ON  bs.match_id   = b.match_id
           AND bs.over_id    = b.over_id
           AND bs.ball_id    = b.ball_id
           AND bs.innings_no = b.innings_no
    LEFT JOIN extra_runs     AS er
           ON  er.match_id   = b.match_id
           AND er.over_id    = b.over_id
           AND er.ball_id    = b.ball_id
           AND er.innings_no = b.innings_no
),
/* 2.  Runs scored while a particular pair batted together  */
partnerships AS (
    SELECT
        match_id,
        player_low,
        player_high,
        SUM(batsman_runs + extra_runs)                                                AS partnership_runs,
        SUM(CASE WHEN striker = player_low  THEN batsman_runs ELSE 0 END)             AS player_low_runs,
        SUM(CASE WHEN striker = player_high THEN batsman_runs ELSE 0 END)             AS player_high_runs
    FROM ball_details
    GROUP BY match_id, player_low, player_high
),
/* 3.  Highest‑run partnership(s) in every match                                    */
max_partnership AS (
    SELECT match_id,
           MAX(partnership_runs) AS max_partnership_runs
    FROM   partnerships
    GROUP BY match_id
),
best_partnerships AS (
    SELECT p.*
    FROM   partnerships AS p
    JOIN   max_partnership AS m
           ON  m.match_id = p.match_id
           AND m.max_partnership_runs = p.partnership_runs
),
/* 4.  Put the higher individual scorer first (ties broken by higher player_id)     */
ordered_partnerships AS (
    SELECT
        match_id,
        CASE
             WHEN player_low_runs  > player_high_runs              THEN player_low
             WHEN player_low_runs  < player_high_runs              THEN player_high
             /* equal individual runs – pick higher id as player1 */
             ELSE CASE WHEN player_low > player_high
                       THEN player_low ELSE player_high END
        END                                                         AS player1_id,
        CASE
             WHEN player_low_runs  > player_high_runs              THEN player_low_runs
             WHEN player_low_runs  < player_high_runs              THEN player_high_runs
             ELSE player_low_runs           /* equal – either value */ 
        END                                                         AS player1_runs,
        CASE
             WHEN player_low_runs  > player_high_runs              THEN player_high
             WHEN player_low_runs  < player_high_runs              THEN player_low
             ELSE CASE WHEN player_low > player_high
                       THEN player_high ELSE player_low END
        END                                                         AS player2_id,
        CASE
             WHEN player_low_runs  > player_high_runs              THEN player_high_runs
             WHEN player_low_runs  < player_high_runs              THEN player_low_runs
             ELSE player_low_runs
        END                                                         AS player2_runs,
        partnership_runs
    FROM best_partnerships
)
/* 5.  Final required output                                                         */
SELECT
    match_id,
    player1_id,
    player1_runs,
    player2_id,
    player2_runs,
    partnership_runs
FROM ordered_partnerships
ORDER BY match_id,
         partnership_runs DESC,
         player1_id DESC,
         player2_id DESC;