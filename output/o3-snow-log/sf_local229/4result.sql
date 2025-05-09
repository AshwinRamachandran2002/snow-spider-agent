/*--------------------------------------------------------------------
  1. Sum the runs scored by every batsman in every match.
  2. Form every unordered pair of batsmen inside a match and calculate
     their combined (partnership) runs.
  3. Re-label the pair so ­that player1 is the one with the higher
     individual score (if scores tie, the higher player_id is player1).
  4. Keep only those pair(s) whose partnership total is the highest
     for that match (ties possible → multiple rows per match).
--------------------------------------------------------------------*/
WITH runs_per_player AS (            -- step-1
    SELECT
        bbb."match_id",
        bbb."striker"       AS player_id,
        SUM(bsc."runs_scored") AS runs_scored
    FROM IPL.IPL.BATSMAN_SCORED bsc
    JOIN IPL.IPL.BALL_BY_BALL  bbb
         ON  bsc."match_id"   = bbb."match_id"
         AND bsc."innings_no" = bbb."innings_no"
         AND bsc."over_id"    = bbb."over_id"
         AND bsc."ball_id"    = bbb."ball_id"
    GROUP BY
        bbb."match_id",
        bbb."striker"
),
pair_runs AS (                      -- step-2 & 3
    SELECT
        r1."match_id",
        /* decide who is player1 and player2 */
        CASE
            WHEN r1.runs_scored > r2.runs_scored THEN r1.player_id
            WHEN r2.runs_scored > r1.runs_scored THEN r2.player_id
            /* equal scores → higher id first */
            WHEN r1.player_id > r2.player_id     THEN r1.player_id
            ELSE                                       r2.player_id
        END                                             AS player1_id,
        CASE
            WHEN r1.runs_scored > r2.runs_scored THEN r1.runs_scored
            WHEN r2.runs_scored > r1.runs_scored THEN r2.runs_scored
            WHEN r1.player_id > r2.player_id     THEN r1.runs_scored
            ELSE                                       r2.runs_scored
        END                                             AS player1_runs,
        CASE
            WHEN r1.runs_scored > r2.runs_scored THEN r2.player_id
            WHEN r2.runs_scored > r1.runs_scored THEN r1.player_id
            WHEN r1.player_id > r2.player_id     THEN r2.player_id
            ELSE                                       r1.player_id
        END                                             AS player2_id,
        CASE
            WHEN r1.runs_scored > r2.runs_scored THEN r2.runs_scored
            WHEN r2.runs_scored > r1.runs_scored THEN r1.runs_scored
            WHEN r1.player_id > r2.player_id     THEN r2.runs_scored
            ELSE                                       r1.runs_scored
        END                                             AS player2_runs,
        r1.runs_scored + r2.runs_scored                AS partnership_runs
    FROM runs_per_player r1
    JOIN runs_per_player r2
         ON  r1."match_id" = r2."match_id"
         AND r1.player_id  < r2.player_id           -- avoid mirror pairs
)
SELECT
    "match_id",
    player1_id  AS "player1_id",
    player1_runs AS "player1_runs",
    player2_id  AS "player2_id",
    player2_runs AS "player2_runs",
    partnership_runs AS "partnership_runs"
FROM pair_runs
QUALIFY partnership_runs = MAX(partnership_runs) OVER (PARTITION BY "match_id")  -- step-4
ORDER BY
    "match_id",
    partnership_runs DESC NULLS LAST,
    player1_id,
    player2_id;