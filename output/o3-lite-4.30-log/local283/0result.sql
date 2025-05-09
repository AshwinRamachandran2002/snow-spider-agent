WITH match_points AS (
    SELECT
        "season",
        "league_id",
        "home_team_api_id" AS team_api_id,
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN 3
            WHEN "home_team_goal" = "away_team_goal" THEN 1
            ELSE 0
        END AS pts
    FROM "Match"
    
    UNION ALL
    
    SELECT
        "season",
        "league_id",
        "away_team_api_id",
        CASE
            WHEN "away_team_goal" > "home_team_goal" THEN 3
            WHEN "home_team_goal" = "away_team_goal" THEN 1
            ELSE 0
        END
    FROM "Match"
),
team_points AS (
    SELECT
        season,
        league_id,
        team_api_id,
        SUM(pts) AS total_points
    FROM match_points
    GROUP BY season, league_id, team_api_id
),
max_points AS (
    SELECT
        season,
        league_id,
        MAX(total_points) AS max_pts
    FROM team_points
    GROUP BY season, league_id
)
SELECT
    tp.season                AS season,
    t."team_long_name"       AS team,
    l."name"                 AS league,
    c."name"                 AS country,
    tp.total_points          AS total_points
FROM       team_points tp
INNER JOIN max_points mp  ON tp.season     = mp.season
                         AND tp.league_id  = mp.league_id
                         AND tp.total_points = mp.max_pts
INNER JOIN "Team"    t ON t."team_api_id" = tp.team_api_id
INNER JOIN "League"  l ON l."id"          = tp.league_id
INNER JOIN "Country" c ON c."id"          = l."country_id"
ORDER BY tp.season,
         c."name",
         l."name",
         t."team_long_name";