/* 1.  Compute every batsman's total runs in each match.               */
/* 2.  Keep only (match, player) pairs where the batsman scored ≥100.  */
/* 3.  Attach the team the batsman represented in that match.          */
/* 4.  Keep only those whose team_id differs from the match_winner.    */
/* 5.  Return the distinct player names.                               */

WITH PLAYER_RUNS AS (           -- total runs by every batsman in every match
    SELECT
        B."match_id",
        BB."striker"              AS "player_id",
        SUM(B."runs_scored")      AS "runs"
    FROM IPL.IPL."BATSMAN_SCORED"  B
    JOIN IPL.IPL."BALL_BY_BALL"   BB
      ON  B."match_id"   = BB."match_id"
      AND B."innings_no" = BB."innings_no"
      AND B."over_id"    = BB."over_id"
      AND B."ball_id"    = BB."ball_id"
    GROUP BY
        B."match_id",
        BB."striker"
),
CENTURIONS AS (                 -- scored at least 100 in the match
    SELECT *
    FROM PLAYER_RUNS
    WHERE "runs" >= 100
),
CENTURIONS_WITH_TEAM AS (       -- add the team they played for in that match
    SELECT
        C."match_id",
        C."player_id",
        C."runs",
        PM."team_id"
    FROM CENTURIONS C
    JOIN IPL.IPL."PLAYER_MATCH" PM
      ON  C."match_id" = PM."match_id"
      AND C."player_id" = PM."player_id"
),
LOSING_CENTURIONS AS (          -- keep only if their team lost that match
    SELECT
        CT.*
    FROM CENTURIONS_WITH_TEAM CT
    JOIN IPL.IPL."MATCH"  M
      ON CT."match_id" = M."match_id"
    WHERE M."match_winner" IS NOT NULL
      AND CT."team_id" <> M."match_winner"
)

SELECT DISTINCT
       P."player_name"
FROM LOSING_CENTURIONS LC
JOIN IPL.IPL."PLAYER" P
  ON LC."player_id" = P."player_id"
ORDER BY P."player_name" NULLS LAST;