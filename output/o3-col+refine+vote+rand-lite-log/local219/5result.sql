WITH
-- every team that ever played in a league
participations AS (
    SELECT "league_id", "home_team_api_id" AS "team_api_id" FROM "Match"
    UNION
    SELECT "league_id", "away_team_api_id"                 FROM "Match"
),
-- count of wins (home or away) for every (league, team) pair
wins AS (
    SELECT  "league_id",
            CASE
                WHEN "home_team_goal" > "away_team_goal" THEN "home_team_api_id"
                WHEN "home_team_goal" < "away_team_goal" THEN "away_team_api_id"
            END                                           AS "team_api_id",
            COUNT(*)                                      AS "wins"
    FROM    "Match"
    WHERE   "home_team_goal" <> "away_team_goal"          -- ignore draws
    GROUP BY "league_id", "team_api_id"
),
-- attach a 0 for teams that never won
league_team_wins AS (
    SELECT  p."league_id",
            p."team_api_id",
            COALESCE(w."wins", 0) AS "wins"
    FROM    participations AS p
    LEFT JOIN wins          AS w
           ON  p."league_id"  = w."league_id"
           AND p."team_api_id" = w."team_api_id"
),
-- minimum wins in every league
min_wins AS (
    SELECT  "league_id",
            MIN("wins") AS "min_wins"
    FROM    league_team_wins
    GROUP BY "league_id"
),
-- pick ONE team (smallest team_api_id) that has that minimum
fewest_wins_team AS (
    SELECT  ltw."league_id",
            MIN(ltw."team_api_id") AS "team_api_id",   -- tie-break
            ltw."wins"
    FROM    league_team_wins AS ltw
    JOIN    min_wins         AS mw
           ON  ltw."league_id" = mw."league_id"
           AND ltw."wins"      = mw."min_wins"
    GROUP BY ltw."league_id"
)
SELECT  lg."name"          AS "league_name",
        tm."team_long_name" AS "team_with_fewest_wins",
        fwt."wins"          AS "total_wins"
FROM    fewest_wins_team AS fwt
JOIN    "League"         AS lg  ON lg."id"        = fwt."league_id"
JOIN    "Team"           AS tm  ON tm."team_api_id" = fwt."team_api_id"
ORDER BY lg."name";