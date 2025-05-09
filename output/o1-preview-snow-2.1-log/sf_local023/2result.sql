WITH 
total_runs_per_player AS (
    SELECT bb."striker" AS "player_id", SUM(bs."runs_scored") AS "total_runs"
    FROM IPL.IPL.BATSMAN_SCORED bs
    INNER JOIN IPL.IPL.BALL_BY_BALL bb
        ON bs."match_id" = bb."match_id"
        AND bs."over_id" = bb."over_id"
        AND bs."ball_id" = bb."ball_id"
        AND bs."innings_no" = bb."innings_no"
    WHERE bs."match_id" IN (SELECT "match_id" FROM IPL.IPL.MATCH WHERE "season_id" = 5)
    GROUP BY bb."striker"
),
matches_played_per_player AS (
    SELECT pm."player_id", COUNT(DISTINCT pm."match_id") AS "matches_played"
    FROM IPL.IPL.PLAYER_MATCH pm
    WHERE pm."match_id" IN (SELECT "match_id" FROM IPL.IPL.MATCH WHERE "season_id" = 5)
    GROUP BY pm."player_id"
),
dismissals_per_player AS (
    SELECT wt."player_out" AS "player_id", COUNT(*) AS "dismissals"
    FROM IPL.IPL.WICKET_TAKEN wt
    WHERE wt."match_id" IN (SELECT "match_id" FROM IPL.IPL.MATCH WHERE "season_id" = 5)
    GROUP BY wt."player_out"
)
SELECT p."player_name" AS "Player_Name",
    ROUND(trp."total_runs" * 1.0 / mpp."matches_played", 4) AS "Average_Runs_Per_Match",
    CASE 
        WHEN COALESCE(dp."dismissals", 0) > 0 THEN ROUND(trp."total_runs" * 1.0 / dp."dismissals", 4)
        ELSE NULL
    END AS "Batting_Average"
FROM total_runs_per_player trp
JOIN matches_played_per_player mpp ON trp."player_id" = mpp."player_id"
LEFT JOIN dismissals_per_player dp ON trp."player_id" = dp."player_id"
JOIN IPL.IPL.PLAYER p ON trp."player_id" = p."player_id"
ORDER BY "Average_Runs_Per_Match" DESC NULLS LAST
LIMIT 5;