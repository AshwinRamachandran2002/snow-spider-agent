WITH per_team_match AS (
    SELECT
        "id"                        AS match_id,
        "season",
        "league_id",
        "country_id",
        "home_team_api_id"          AS team_api_id,
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN 3
            WHEN "home_team_goal" = "away_team_goal" THEN 1
            ELSE 0
        END                         AS points
    FROM "Match"
    WHERE "home_team_goal" IS NOT NULL
      AND "away_team_goal" IS NOT NULL

    UNION ALL

    SELECT
        "id"                        AS match_id,
        "season",
        "league_id",
        "country_id",
        "away_team_api_id"          AS team_api_id,
        CASE
            WHEN "away_team_goal" > "home_team_goal" THEN 3
            WHEN "away_team_goal" = "home_team_goal" THEN 1
            ELSE 0
        END                         AS points
    FROM "Match"
    WHERE "home_team_goal" IS NOT NULL
      AND "away_team_goal" IS NOT NULL
),
season_team_points AS (
    SELECT
        "season",
        "league_id",
        "country_id",
        team_api_id,
        SUM(points) AS total_points
    FROM per_team_match
    GROUP BY "season", "league_id", "country_id", team_api_id
),
season_max AS (
    SELECT
        "season",
        "league_id",
        MAX(total_points) AS max_points
    FROM season_team_points
    GROUP BY "season", "league_id"
),
champions AS (
    SELECT st.*
    FROM season_team_points st
    JOIN season_max sm
      ON  st."season"    = sm."season"
     AND st."league_id"  = sm."league_id"
     AND st.total_points = sm.max_points
)
SELECT
    champions."season"   AS season,
    t."team_long_name"   AS team,
    l."name"             AS league,
    c."name"             AS country,
    champions.total_points
FROM champions
JOIN "Team"    AS t ON t."team_api_id" = champions.team_api_id
JOIN "League"  AS l ON l."id"          = champions."league_id"
JOIN "Country" AS c ON c."id"          = champions."country_id"
ORDER BY season, league, team;