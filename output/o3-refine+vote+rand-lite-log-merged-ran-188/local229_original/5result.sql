WITH ball_with_runs AS (
    /* all balls with the two current batsmen
       and the runs scored off that ball                         */
    SELECT bb.match_id,
           bb.striker,
           bb.non_striker,
           CASE WHEN bb.striker > bb.non_striker THEN bb.striker ELSE bb.non_striker END AS p_high,
           CASE WHEN bb.striker > bb.non_striker THEN bb.non_striker ELSE bb.striker END AS p_low,
           COALESCE(bs.runs_scored,0) AS runs_for_striker
    FROM   ball_by_ball      AS bb
    LEFT  JOIN batsman_scored AS bs
           ON  bb.match_id   = bs.match_id
           AND bb.over_id    = bs.over_id
           AND bb.ball_id    = bs.ball_id
           AND bb.innings_no = bs.innings_no
),
/* aggregate every (unordered) pair in a match */
partnership AS (
    SELECT match_id,
           p_high,                       -- the larger player_id in the pair
           p_low,                        -- the smaller player_id in the pair
           SUM(runs_for_striker)                                                  AS partnership_runs,
           SUM(CASE WHEN striker = p_high THEN runs_for_striker ELSE 0 END)       AS runs_high,
           SUM(CASE WHEN striker = p_low  THEN runs_for_striker ELSE 0 END)       AS runs_low
    FROM   ball_with_runs
    GROUP  BY match_id, p_high, p_low
),
/* best partnership score in every match */
best_per_match AS (
    SELECT match_id,
           MAX(partnership_runs) AS max_runs
    FROM   partnership
    GROUP  BY match_id
),
/* keep only the partnership(s) that reach that maximum */
top_partnerships AS (
    SELECT p.*
    FROM   partnership p
    JOIN   best_per_match b
           ON p.match_id = b.match_id
          AND p.partnership_runs = b.max_runs
)
/* reorder the two players as required by the rules */
SELECT
    match_id,
    CASE
        WHEN runs_high > runs_low                             THEN p_high
        WHEN runs_high < runs_low                             THEN p_low
        WHEN runs_high = runs_low AND p_high > p_low          THEN p_high
        ELSE                                                       p_low
    END                                 AS player1_id,
    CASE
        WHEN runs_high > runs_low                             THEN runs_high
        WHEN runs_high < runs_low                             THEN runs_low
        WHEN runs_high = runs_low AND p_high > p_low          THEN runs_high
        ELSE                                                       runs_low
    END                                 AS player1_score,
    CASE
        WHEN runs_high > runs_low                             THEN p_low
        WHEN runs_high < runs_low                             THEN p_high
        WHEN runs_high = runs_low AND p_high > p_low          THEN p_low
        ELSE                                                       p_high
    END                                 AS player2_id,
    CASE
        WHEN runs_high > runs_low                             THEN runs_low
        WHEN runs_high < runs_low                             THEN runs_high
        WHEN runs_high = runs_low AND p_high > p_low          THEN runs_low
        ELSE                                                       runs_high
    END                                 AS player2_score,
    partnership_runs
FROM   top_partnerships
ORDER  BY match_id, player1_id, player2_id;