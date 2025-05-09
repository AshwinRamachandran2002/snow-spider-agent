/*  Highest-scoring batting partnerships in every match                     */
/*  – player with the bigger individual contribution is shown as PLAYER 1  */
/*  – if both score the same, higher player_id becomes PLAYER 1            */
/*  – ties on total partnership runs are all returned                     */

WITH ball_runs AS (          -- runs made on every ball together with the two batsmen involved
    SELECT
        bb."match_id",
        LEAST(bb."striker", bb."non_striker")      AS pair_low,         -- unordered pair key
        GREATEST(bb."striker", bb."non_striker")   AS pair_high,
        COALESCE(bs."runs_scored", 0)                                  AS batsman_runs,
        COALESCE(bs."runs_scored", 0) + COALESCE(er."extra_runs", 0)   AS total_ball_runs,
        bb."striker"                                                  -- needed for individual runs
    FROM IPL.IPL.BALL_BY_BALL  bb
    LEFT JOIN IPL.IPL.BATSMAN_SCORED bs
           ON bb."match_id"  = bs."match_id"
          AND bb."innings_no"= bs."innings_no"
          AND bb."over_id"   = bs."over_id"
          AND bb."ball_id"   = bs."ball_id"
    LEFT JOIN IPL.IPL.EXTRA_RUNS er
           ON bb."match_id"  = er."match_id"
          AND bb."innings_no"= er."innings_no"
          AND bb."over_id"   = er."over_id"
          AND bb."ball_id"   = er."ball_id"
),
partnership AS (             -- aggregate runs for every partnership in the match
    SELECT
        "match_id",
        pair_low,
        pair_high,
        SUM(total_ball_runs)                                                AS total_runs,
        SUM(CASE WHEN "striker" = pair_low  THEN batsman_runs ELSE 0 END)   AS runs_low,
        SUM(CASE WHEN "striker" = pair_high THEN batsman_runs ELSE 0 END)   AS runs_high
    FROM ball_runs
    GROUP BY "match_id", pair_low, pair_high
),
max_in_match AS (            -- highest partnership score in each match
    SELECT
        p.*,
        MAX(total_runs) OVER (PARTITION BY "match_id") AS max_total
    FROM partnership p
),
top_partnership AS (         -- keep only partnerships that reach that maximum (may be >1)
    SELECT *
    FROM max_in_match
    WHERE total_runs = max_total
),
ordered AS (                 -- arrange batsmen as PLAYER-1 / PLAYER-2 per rules
    SELECT
        "match_id",
        CASE 
            WHEN runs_low  > runs_high THEN pair_low
            WHEN runs_low  < runs_high THEN pair_high
            ELSE pair_high                                -- equal runs ⇒ larger id first
        END                                             AS player1_id,
        CASE 
            WHEN runs_low  > runs_high THEN runs_low
            WHEN runs_low  < runs_high THEN runs_high
            ELSE runs_high
        END                                             AS player1_runs,
        CASE 
            WHEN runs_low  > runs_high THEN pair_high
            WHEN runs_low  < runs_high THEN pair_low
            ELSE pair_low
        END                                             AS player2_id,
        CASE 
            WHEN runs_low  > runs_high THEN runs_high
            WHEN runs_low  < runs_high THEN runs_low
            ELSE runs_low
        END                                             AS player2_runs,
        total_runs                                      AS partnership_runs
    FROM top_partnership
)
SELECT
    "match_id",
    player1_id   AS "player1_id",
    player1_runs AS "player1_runs",
    player2_id   AS "player2_id",
    player2_runs AS "player2_runs",
    partnership_runs AS "partnership_runs"
FROM ordered
ORDER BY "match_id",
         "partnership_runs" DESC NULLS LAST;