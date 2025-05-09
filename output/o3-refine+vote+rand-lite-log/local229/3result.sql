WITH ball_runs AS (          --  runs coming from the bat together with the 2 batsmen
    SELECT  b.match_id ,
            b.striker ,
            b.non_striker ,
            s.runs_scored
    FROM    ball_by_ball  b
    JOIN    batsman_scored s
           ON s.match_id   = b.match_id
          AND s.over_id    = b.over_id
          AND s.ball_id    = b.ball_id
          AND s.innings_no = b.innings_no
    WHERE   b.striker      IS NOT NULL           -- sanity‑checks
      AND   b.non_striker  IS NOT NULL
),
pairs AS (                   --  create an ordered (low,high) pair id for every ball
    SELECT  match_id ,
            CASE WHEN striker < non_striker THEN striker ELSE non_striker END AS p_low ,
            CASE WHEN striker < non_striker THEN non_striker ELSE striker END AS p_high ,
            striker ,
            runs_scored
    FROM    ball_runs
),
partnership AS (             --  aggregate runs for every (match , pair)
    SELECT  match_id ,
            p_low ,
            p_high ,
            SUM( CASE WHEN striker = p_low  THEN runs_scored ELSE 0 END ) AS low_runs ,
            SUM( CASE WHEN striker = p_high THEN runs_scored ELSE 0 END ) AS high_runs ,
            SUM(runs_scored)                                            AS total_runs
    FROM    pairs
    GROUP BY match_id , p_low , p_high
),
max_partnership AS (         --  highest partnership score per match
    SELECT  match_id ,
            MAX(total_runs) AS max_runs
    FROM    partnership
    GROUP BY match_id
),
top_pairs AS (               --  keep every pair that reaches that maximum (ties possible)
    SELECT  p.*
    FROM    partnership p
    JOIN    max_partnership m
           ON p.match_id = m.match_id
          AND p.total_runs = m.max_runs
)
SELECT  match_id ,

        /*  decide which player is player‑1 according to the rules */
        CASE
            WHEN low_runs  >  high_runs                 THEN p_low
            WHEN low_runs  <  high_runs                 THEN p_high
            WHEN p_low     >  p_high                    THEN p_low
            ELSE                                            p_high
        END                                               AS player1_id ,

        CASE
            WHEN low_runs  >  high_runs                 THEN low_runs
            WHEN low_runs  <  high_runs                 THEN high_runs
            WHEN p_low     >  p_high                    THEN low_runs
            ELSE                                            high_runs
        END                                               AS player1_score ,

        CASE
            WHEN low_runs  >  high_runs                 THEN p_high
            WHEN low_runs  <  high_runs                 THEN p_low
            WHEN p_low     >  p_high                    THEN p_high
            ELSE                                            p_low
        END                                               AS player2_id ,

        CASE
            WHEN low_runs  >  high_runs                 THEN high_runs
            WHEN low_runs  <  high_runs                 THEN low_runs
            WHEN p_low     >  p_high                    THEN high_runs
            ELSE                                            low_runs
        END                                               AS player2_score ,

        total_runs                                         AS partnership_score
FROM    top_pairs
ORDER BY match_id , player1_id , player2_id;