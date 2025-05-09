WITH ball_runs AS (
    /*  Runs (batsman + extras) and the two players who were together at the crease  */
    SELECT
        b.match_id,
        b.striker,
        b.non_striker,
        CASE WHEN b.striker < b.non_striker THEN b.striker ELSE b.non_striker END AS player_low,
        CASE WHEN b.striker > b.non_striker THEN b.striker ELSE b.non_striker END AS player_high,
        COALESCE(s.runs_scored,0) AS batsman_runs,
        COALESCE(e.extra_runs,0)  AS extra_runs
    FROM ball_by_ball AS b
    LEFT JOIN batsman_scored AS s
           ON  s.match_id   = b.match_id
           AND s.over_id    = b.over_id
           AND s.ball_id    = b.ball_id
           AND s.innings_no = b.innings_no
    LEFT JOIN extra_runs  AS e
           ON  e.match_id   = b.match_id
           AND e.over_id    = b.over_id
           AND e.ball_id    = b.ball_id
           AND e.innings_no = b.innings_no
    WHERE b.striker IS NOT NULL
      AND b.non_striker IS NOT NULL
),
pair_agg AS (
    /*  Aggregate to get partnership‑level figures  */
    SELECT
        match_id,
        player_low,
        player_high,
        SUM(batsman_runs + extra_runs)                                                   AS partnership_runs,
        SUM(CASE WHEN striker = player_low  THEN batsman_runs ELSE 0 END)                AS runs_low,
        SUM(CASE WHEN striker = player_high THEN batsman_runs ELSE 0 END)                AS runs_high
    FROM ball_runs
    GROUP BY match_id, player_low, player_high
),
pair_ordered AS (
    /*  Arrange players inside the pair as required by the rules  */
    SELECT
        match_id,
        CASE
            WHEN runs_low > runs_high THEN player_low
            WHEN runs_low < runs_high THEN player_high
            ELSE CASE WHEN player_high > player_low THEN player_high ELSE player_low END
        END AS player1_id,
        CASE
            WHEN runs_low > runs_high THEN runs_low
            WHEN runs_low < runs_high THEN runs_high
            ELSE runs_high
        END AS player1_runs,
        CASE
            WHEN runs_low > runs_high THEN player_high
            WHEN runs_low < runs_high THEN player_low
            ELSE CASE WHEN player_high > player_low THEN player_low ELSE player_high END
        END AS player2_id,
        CASE
            WHEN runs_low > runs_high THEN runs_high
            WHEN runs_low < runs_high THEN runs_low
            ELSE runs_low
        END AS player2_runs,
        partnership_runs
    FROM pair_agg
),
max_partnership AS (
    /*  Identify the highest partnership runs for each match (keep ties)  */
    SELECT
        *,
        MAX(partnership_runs) OVER (PARTITION BY match_id) AS max_partnership_runs
    FROM pair_ordered
)
SELECT
    match_id,
    player1_id,
    player1_runs,
    player2_id,
    player2_runs,
    partnership_runs
FROM max_partnership
WHERE partnership_runs = max_partnership_runs
ORDER BY match_id, player1_id DESC, player2_id DESC;