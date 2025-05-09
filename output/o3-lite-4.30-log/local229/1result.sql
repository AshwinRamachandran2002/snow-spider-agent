WITH ball AS (                                   -- add batting & extra runs to every delivery
    SELECT  b.match_id ,
            b.striker ,
            b.non_striker ,
            COALESCE(s.runs_scored,0) AS bat_runs ,
            COALESCE(e.extra_runs ,0) AS extra_runs
    FROM   ball_by_ball   AS b
    LEFT JOIN batsman_scored AS s
           ON  s.match_id  = b.match_id
          AND s.over_id   = b.over_id
          AND s.ball_id   = b.ball_id
          AND s.innings_no = b.innings_no
    LEFT JOIN extra_runs    AS e
           ON  e.match_id  = b.match_id
          AND e.over_id   = b.over_id
          AND e.ball_id   = b.ball_id
          AND e.innings_no = b.innings_no
),
pair_delivery AS (                              -- normalise pair order – low‑id / high‑id
    SELECT  match_id ,
            CASE WHEN striker < non_striker THEN striker ELSE non_striker END AS p_low ,
            CASE WHEN striker < non_striker THEN non_striker ELSE striker END AS p_high ,
            striker        AS batsman_id ,
            bat_runs ,
            extra_runs
    FROM    ball
),
partnership AS (                                -- aggregate per match & pair
    SELECT  match_id ,
            p_low ,
            p_high ,
            SUM(bat_runs + extra_runs)                                       AS partnership_runs ,
            SUM(CASE WHEN batsman_id = p_low  THEN bat_runs ELSE 0 END)      AS p_low_runs ,
            SUM(CASE WHEN batsman_id = p_high THEN bat_runs ELSE 0 END)      AS p_high_runs
    FROM    pair_delivery
    GROUP BY match_id, p_low, p_high
),
max_part AS (                                   -- highest partnership score in each match
    SELECT  match_id ,
            MAX(partnership_runs) AS max_runs
    FROM    partnership
    GROUP BY match_id
),
best AS (                                       -- keep the (possibly tied) best partnerships
    SELECT  p.*
    FROM    partnership p
    JOIN    max_part m
           ON p.match_id = m.match_id
          AND p.partnership_runs = m.max_runs
)
SELECT
    match_id ,
    CASE                                            -- decide who is player‑1
        WHEN p_low_runs > p_high_runs THEN p_low
        WHEN p_low_runs < p_high_runs THEN p_high
        ELSE p_high                                 -- tie → higher id first
    END                                           AS player1_id ,
    CASE
        WHEN p_low_runs > p_high_runs THEN p_low_runs
        WHEN p_low_runs < p_high_runs THEN p_high_runs
        ELSE p_high_runs
    END                                           AS player1_runs ,
    CASE
        WHEN p_low_runs > p_high_runs THEN p_high
        WHEN p_low_runs < p_high_runs THEN p_low
        ELSE p_low
    END                                           AS player2_id ,
    CASE
        WHEN p_low_runs > p_high_runs THEN p_high_runs
        WHEN p_low_runs < p_high_runs THEN p_low_runs
        ELSE p_low_runs
    END                                           AS player2_runs ,
    partnership_runs
FROM   best
ORDER BY match_id , player1_id DESC , player2_id DESC;