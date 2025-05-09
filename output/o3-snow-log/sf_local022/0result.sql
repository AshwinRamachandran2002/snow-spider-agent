WITH
-- Runs scored by every batsman (striker) in each match
player_runs AS (
    SELECT
        bb."match_id",
        bb."team_batting"          AS "team_id",
        bb."striker"               AS "player_id",
        SUM(bs."runs_scored")      AS "total_runs"
    FROM IPL.IPL.BALL_BY_BALL  bb
    JOIN IPL.IPL.BATSMAN_SCORED bs
      ON bs."match_id"   = bb."match_id"
     AND bs."innings_no" = bb."innings_no"
     AND bs."over_id"    = bb."over_id"
     AND bs."ball_id"    = bb."ball_id"
    GROUP BY
        bb."match_id",
        bb."team_batting",
        bb."striker"
    HAVING SUM(bs."runs_scored") >= 100          -- at least 100 runs
),

-- Identify the losing team for every completed match
loser_team AS (
    SELECT
        "match_id",
        CASE 
            WHEN "match_winner" = "team_1" THEN "team_2"
            WHEN "match_winner" = "team_2" THEN "team_1"
            ELSE NULL
        END AS "loser_team_id"
    FROM IPL.IPL.MATCH
    WHERE "outcome_type" = 'Result'
      AND "match_winner" IS NOT NULL
)

-- Players who scored 100+ while playing for the losing side
SELECT DISTINCT
       pl."player_name"
FROM player_runs  pr
JOIN loser_team   lt  ON pr."match_id" = lt."match_id"
                     AND pr."team_id"  = lt."loser_team_id"
JOIN IPL.IPL.PLAYER pl ON pr."player_id" = pl."player_id"
WHERE lt."loser_team_id" IS NOT NULL
ORDER BY pl."player_name";