WITH teams_in_league AS (
    SELECT "league_id", "home_team_api_id" AS "team_api_id"
    FROM "Match"
    UNION
    SELECT "league_id", "away_team_api_id"
    FROM "Match"
),
wins AS (
    SELECT "league_id",
           CASE
               WHEN "home_team_goal" > "away_team_goal" THEN "home_team_api_id"
               WHEN "away_team_goal" > "home_team_goal" THEN "away_team_api_id"
           END AS "winner_team_api_id"
    FROM "Match"
),
wins_per_team AS (
    SELECT "league_id",
           "winner_team_api_id" AS "team_api_id",
           COUNT(*) AS "wins"
    FROM wins
    WHERE "winner_team_api_id" IS NOT NULL
    GROUP BY "league_id", "winner_team_api_id"
),
all_team_wins AS (
    SELECT til."league_id",
           til."team_api_id",
           COALESCE(wpt."wins", 0) AS "wins"
    FROM teams_in_league til
    LEFT JOIN wins_per_team wpt
           ON wpt."league_id" = til."league_id"
          AND wpt."team_api_id" = til."team_api_id"
),
fewest AS (
    SELECT "league_id",
           MIN("wins") AS "min_wins"
    FROM all_team_wins
    GROUP BY "league_id"
)
SELECT l."name"           AS league_name,
       t."team_long_name" AS team_name,
       atw."wins"         AS total_wins
FROM   all_team_wins atw
JOIN   fewest f   ON f."league_id" = atw."league_id"
                 AND f."min_wins"  = atw."wins"
JOIN   "League" l ON l."id" = atw."league_id"
JOIN   "Team"   t ON t."team_api_id" = atw."team_api_id"
GROUP  BY atw."league_id"
HAVING t."team_api_id" = MIN(t."team_api_id")
ORDER  BY l."name";