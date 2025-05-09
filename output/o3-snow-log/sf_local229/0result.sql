WITH ball_data AS (         -- delivery-level facts + runs + wicket flag
    SELECT
        bb."match_id",
        bb."innings_no",
        bb."over_id",
        bb."ball_id",
        bb."striker",
        bb."non_striker",
        COALESCE(bs."runs_scored", 0)                                  AS runs_scored,
        CASE WHEN wt."match_id" IS NOT NULL THEN 1 ELSE 0 END          AS wicket_flag
    FROM IPL.IPL."BALL_BY_BALL" bb
    LEFT JOIN IPL.IPL."BATSMAN_SCORED" bs
           ON  bb."match_id"   = bs."match_id"
          AND bb."innings_no"  = bs."innings_no"
          AND bb."over_id"     = bs."over_id"
          AND bb."ball_id"     = bs."ball_id"
    LEFT JOIN ( SELECT DISTINCT
                       "match_id", "innings_no", "over_id", "ball_id"
                FROM IPL.IPL."WICKET_TAKEN"
              ) wt
           ON  bb."match_id"   = wt."match_id"
          AND bb."innings_no"  = wt."innings_no"
          AND bb."over_id"     = wt."over_id"
          AND bb."ball_id"     = wt."ball_id"
),
ball_with_partnership AS (    -- attach partnership identifier
    SELECT
        *,
        COALESCE(
            SUM(wicket_flag) OVER (
                PARTITION BY "match_id", "innings_no"
                ORDER BY "over_id", "ball_id"
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ),
            0
        ) AS partnership_id
    FROM ball_data
),
player_runs AS (              -- runs by every batsman inside a partnership
    SELECT
        "match_id",
        partnership_id,
        "striker"                          AS player_id,
        SUM(runs_scored)                   AS player_runs
    FROM ball_with_partnership
    GROUP BY "match_id", partnership_id, "striker"
),
partnership_pairs AS (        -- two batsmen that make a partnership
    SELECT
        pr1."match_id",
        pr1.partnership_id,
        pr1.player_id                      AS p1,
        pr1.player_runs                    AS p1_runs,
        pr2.player_id                      AS p2,
        pr2.player_runs                    AS p2_runs,
        pr1.player_runs + pr2.player_runs  AS partnership_runs
    FROM player_runs pr1
    JOIN player_runs pr2
          ON pr1."match_id"     = pr2."match_id"
         AND pr1.partnership_id = pr2.partnership_id
         AND pr1.player_id      < pr2.player_id          -- one row per pair
),
ranked_partnerships AS (      -- choose player-1 / player-2 & rank
    SELECT
        "match_id",
        partnership_id,
        CASE
            WHEN (p1_runs > p2_runs) OR (p1_runs = p2_runs AND p1 > p2)
                 THEN p1 ELSE p2
        END  AS player1_id,
        CASE
            WHEN (p1_runs > p2_runs) OR (p1_runs = p2_runs AND p1 > p2)
                 THEN p1_runs ELSE p2_runs
        END  AS player1_runs,
        CASE
            WHEN (p1_runs > p2_runs) OR (p1_runs = p2_runs AND p1 > p2)
                 THEN p2 ELSE p1
        END  AS player2_id,
        CASE
            WHEN (p1_runs > p2_runs) OR (p1_runs = p2_runs AND p1 > p2)
                 THEN p2_runs ELSE p1_runs
        END  AS player2_runs,
        partnership_runs,
        DENSE_RANK() OVER (PARTITION BY "match_id"
                           ORDER BY partnership_runs DESC)  AS rk
    FROM partnership_pairs
)
SELECT
    "match_id",
    player1_id,
    player1_runs,
    player2_id,
    player2_runs,
    partnership_runs
FROM ranked_partnerships
WHERE rk = 1                          -- highest partnership(s) per match
ORDER BY "match_id", player1_id;