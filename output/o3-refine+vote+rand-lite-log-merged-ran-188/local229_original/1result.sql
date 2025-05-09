WITH pair_ball AS (
    /* 1.  Get every ball with the two batsmen at the crease and the runs scored */
    SELECT
        b.match_id,
        /* keep the pair in a fixed (ascending) order so that (A,B) == (B,A) */
        CASE WHEN b.striker < b.non_striker THEN b.striker ELSE b.non_striker END AS player_a,
        CASE WHEN b.striker < b.non_striker THEN b.non_striker ELSE b.striker END AS player_b,
        b.striker,                         -- the batsman who actually scored on this ball
        bs.runs_scored                     -- runs credited to the striker
    FROM ball_by_ball  AS b
    JOIN batsman_scored AS bs
      ON b.match_id   = bs.match_id
     AND b.over_id    = bs.over_id
     AND b.ball_id    = bs.ball_id
     AND b.innings_no = bs.innings_no
),
pair_agg AS (
    /* 2.  Aggregate runs for every (unordered) pair inside each match */
    SELECT
        match_id,
        player_a,
        player_b,
        SUM(runs_scored)                                                   AS total_runs,
        SUM(CASE WHEN striker = player_a THEN runs_scored ELSE 0 END)      AS runs_a,
        SUM(CASE WHEN striker = player_b THEN runs_scored ELSE 0 END)      AS runs_b
    FROM pair_ball
    GROUP BY match_id, player_a, player_b
),
max_pair AS (
    /* 3.  Highest‑scoring partnership(s) of every match */
    SELECT match_id, MAX(total_runs) AS max_runs
    FROM pair_agg
    GROUP BY match_id
),
best_pairs AS (
    SELECT p.*
    FROM pair_agg p
    JOIN max_pair m
      ON p.match_id = m.match_id
     AND p.total_runs = m.max_runs          -- keep ties on total partnership runs
),
ordered_pairs AS (
    /* 4.  Put the partner with the higher individual contribution first.
            If equal, the higher player_id comes first.                */
    SELECT
        match_id,
        CASE
            WHEN runs_a > runs_b THEN player_a
            WHEN runs_b > runs_a THEN player_b
            ELSE player_b                      -- equal runs ⇒ higher id (player_b) first
        END                                                    AS player1_id,
        CASE
            WHEN runs_a > runs_b THEN runs_a
            WHEN runs_b > runs_a THEN runs_b
            ELSE runs_b
        END                                                    AS player1_runs,
        CASE
            WHEN runs_a > runs_b THEN player_b
            WHEN runs_b > runs_a THEN player_a
            ELSE player_a
        END                                                    AS player2_id,
        CASE
            WHEN runs_a > runs_b THEN runs_b
            WHEN runs_b > runs_a THEN runs_a
            ELSE runs_a
        END                                                    AS player2_runs,
        total_runs
    FROM best_pairs
)
SELECT
    match_id,
    player1_id AS player1,
    player1_runs,
    player2_id AS player2,
    player2_runs,
    total_runs  AS partnership_runs
FROM ordered_pairs
ORDER BY match_id, player1_id, player2_id;