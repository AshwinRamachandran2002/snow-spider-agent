WITH ball_runs AS (
    -- 1.  Add the runs scored on every delivery to the two batsmen who were together
    SELECT  b.match_id,
            b.striker,
            b.non_striker,
            bs.runs_scored
    FROM    ball_by_ball   AS b
    JOIN    batsman_scored AS bs
           ON bs.match_id   = b.match_id
          AND bs.over_id    = b.over_id
          AND bs.ball_id    = b.ball_id
          AND bs.innings_no = b.innings_no
),
partner AS (
    -- 2.  Aggregate to get, for every pair in every match,
    --     • each player’s own runs inside the partnership
    --     • the total partnership runs
    SELECT  match_id,
            CASE WHEN striker > non_striker THEN striker ELSE non_striker END AS p_high,
            CASE WHEN striker > non_striker THEN non_striker ELSE striker END AS p_low,
            SUM(CASE WHEN striker > non_striker THEN runs_scored ELSE 0 END) AS runs_high,
            SUM(CASE WHEN striker < non_striker THEN runs_scored ELSE 0 END) AS runs_low,
            SUM(runs_scored)                                              AS partnership_runs
    FROM    ball_runs
    GROUP   BY match_id, p_high, p_low
),
ordered AS (
    -- 3.  Decide which player is player-1 / player-2
    SELECT  match_id,
            CASE
                 WHEN runs_high > runs_low                              THEN p_high
                 WHEN runs_high < runs_low                              THEN p_low
                 WHEN runs_high = runs_low AND p_high > p_low           THEN p_high
                 ELSE                                                       p_low
            END                                                          AS player1_id,
            CASE
                 WHEN runs_high > runs_low                              THEN p_low
                 WHEN runs_high < runs_low                              THEN p_high
                 WHEN runs_high = runs_low AND p_high > p_low           THEN p_low
                 ELSE                                                       p_high
            END                                                          AS player2_id,
            CASE
                 WHEN runs_high > runs_low THEN runs_high
                 WHEN runs_high < runs_low THEN runs_low
                 ELSE                     runs_high
            END                                                          AS player1_runs,
            CASE
                 WHEN runs_high > runs_low THEN runs_low
                 WHEN runs_high < runs_low THEN runs_high
                 ELSE                     runs_low
            END                                                          AS player2_runs,
            partnership_runs
    FROM   partner
),
with_max AS (
    -- 4.  Keep only the partnership(s) with the highest runs in each match
    SELECT  o.*,
            MAX(partnership_runs) OVER (PARTITION BY match_id) AS max_pr
    FROM    ordered o
)
SELECT  match_id,
        player1_id,
        player1_runs,
        player2_id,
        player2_runs,
        partnership_runs
FROM    with_max
WHERE   partnership_runs = max_pr      -- ties allowed
ORDER BY match_id,                     -- final presentation order
         player1_id DESC,
         player2_id DESC;