WITH season_matches AS (           -- all matches of season 5
    SELECT "match_id"
    FROM IPL.IPL.MATCH
    WHERE "season_id" = 5
),
player_matches AS (               -- number of matches each player appeared in season 5
    SELECT "player_id",
           COUNT(DISTINCT "match_id") AS matches_played
    FROM IPL.IPL.PLAYER_MATCH
    WHERE "match_id" IN (SELECT "match_id" FROM season_matches)
    GROUP BY "player_id"
),
player_runs AS (                  -- total runs scored by each player in season 5
    SELECT bb."striker" AS player_id,
           SUM(bs."runs_scored")  AS total_runs
    FROM IPL.IPL.BATSMAN_SCORED bs
    JOIN IPL.IPL.BALL_BY_BALL  bb
         ON  bs."match_id"   = bb."match_id"
         AND bs."over_id"    = bb."over_id"
         AND bs."ball_id"    = bb."ball_id"
         AND bs."innings_no" = bb."innings_no"
    WHERE bs."match_id" IN (SELECT "match_id" FROM season_matches)
    GROUP BY bb."striker"
)
SELECT
    pl."player_name",
    ROUND(pr.total_runs::DECIMAL / pm.matches_played, 4) AS batting_average
FROM player_runs     pr
JOIN player_matches  pm ON pr.player_id = pm."player_id"
JOIN IPL.IPL.PLAYER  pl ON pl."player_id" = pr.player_id
ORDER BY batting_average DESC NULLS LAST
LIMIT 5;