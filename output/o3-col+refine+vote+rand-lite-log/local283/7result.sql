WITH match_points AS (
    -- award 3-1-0 points to every team for every match (home & away)
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
            WHEN "away_team_goal" = "home_team_goal" THEN 1
            ELSE 0
        END
    FROM "Match"
),
season_team_points AS (
    -- aggregate to total points each team earned per (season , league)
    SELECT
        "season",
        "league_id",
        team_api_id,
        SUM(pts) AS total_points
    FROM   match_points
    GROUP  BY "season", "league_id", team_api_id
),
ranked AS (
    -- rank teams by points to find the champion of every league season
    SELECT
        stp.*,
        ROW_NUMBER() OVER (PARTITION BY stp."season", stp."league_id"
                           ORDER BY stp.total_points DESC) AS rn
    FROM   season_team_points AS stp
)
-- final output: one champion per (season , league)
SELECT
    r."season",
    c."name"                 AS country,
    l."name"                 AS league,
    t."team_long_name"       AS champion_team,
    r.total_points           AS points
FROM   ranked   AS r
JOIN   "Team"    AS t ON r.team_api_id = t.team_api_id
JOIN   "League"  AS l ON r."league_id" = l."id"
JOIN   "Country" AS c ON l."country_id" = c."id"
WHERE  r.rn = 1
ORDER  BY r."season", c."name", l."name";