WITH per_ball AS (
    /*  Every delivery with the two batsmen that were together  */
    SELECT
        bb.match_id,
        /* keep the pair in a fixed (low‑id, high‑id) order                      */
        CASE WHEN bb.striker < bb.non_striker THEN bb.striker ELSE bb.non_striker END AS p_low,
        CASE WHEN bb.striker < bb.non_striker THEN bb.non_striker ELSE bb.striker END AS p_high,
        bb.striker,
        COALESCE(bs.runs_scored ,0)                         AS batsman_runs,   -- runs to the striker
        COALESCE(er.extra_runs  ,0)                         AS extra_runs      -- extras in the partnership
    FROM ball_by_ball bb
    LEFT JOIN batsman_scored bs
           ON bs.match_id   = bb.match_id
          AND bs.over_id    = bb.over_id
          AND bs.ball_id    = bb.ball_id
          AND bs.innings_no = bb.innings_no
    LEFT JOIN extra_runs er
           ON er.match_id   = bb.match_id
          AND er.over_id    = bb.over_id
          AND er.ball_id    = bb.ball_id
          AND er.innings_no = bb.innings_no
),
partnership AS (
    /*  Aggregate to get runs for every pair in a match                         */
    SELECT
        match_id,
        p_low AS p1,
        p_high AS p2,
        SUM(CASE WHEN striker = p_low  THEN batsman_runs ELSE 0 END) AS p1_runs,
        SUM(CASE WHEN striker = p_high THEN batsman_runs ELSE 0 END) AS p2_runs,
        SUM(batsman_runs + extra_runs)                               AS partnership_runs
    FROM per_ball
    GROUP BY match_id, p_low, p_high
),
ordered_partnership AS (
    /*  Put the higher individual scorer first (or higher id if equal)          */
    SELECT
        match_id,
        CASE
            WHEN p1_runs > p2_runs                    THEN p1
            WHEN p1_runs < p2_runs                    THEN p2
            WHEN p1        > p2                       THEN p1
            ELSE                                           p2
        END                                           AS player1_id,
        CASE
            WHEN p1_runs > p2_runs                    THEN p1_runs
            WHEN p1_runs < p2_runs                    THEN p2_runs
            WHEN p1        > p2                       THEN p1_runs
            ELSE                                           p2_runs
        END                                           AS player1_runs,
        CASE
            WHEN p1_runs > p2_runs                    THEN p2
            WHEN p1_runs < p2_runs                    THEN p1
            WHEN p1        > p2                       THEN p2
            ELSE                                           p1
        END                                           AS player2_id,
        CASE
            WHEN p1_runs > p2_runs                    THEN p2_runs
            WHEN p1_runs < p2_runs                    THEN p1_runs
            WHEN p1        > p2                       THEN p2_runs
            ELSE                                           p1_runs
        END                                           AS player2_runs,
        partnership_runs
    FROM partnership
),
ranked AS (
    /*  Highest‑scoring partnership(s) of each match                            */
    SELECT
        *,
        RANK() OVER (PARTITION BY match_id ORDER BY partnership_runs DESC) AS rnk
    FROM ordered_partnership
)
SELECT
    match_id,
    player1_id  AS player_1_id,
    player1_runs AS player_1_score,
    player2_id  AS player_2_id,
    player2_runs AS player_2_score,
    partnership_runs
FROM ranked
WHERE rnk = 1
ORDER BY match_id, player1_id, player2_id;