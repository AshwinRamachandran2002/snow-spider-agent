WITH points_per_match AS (
    SELECT
        M."season",
        M."home_team_api_id" AS "team_api_id",
        M."league_id",
        M."country_id",
        CASE
            WHEN M."home_team_goal" > M."away_team_goal" THEN 3
            WHEN M."home_team_goal" = M."away_team_goal" THEN 1
            ELSE 0
        END AS "points"
    FROM EU_SOCCER.EU_SOCCER.MATCH M
    UNION ALL
    SELECT
        M."season",
        M."away_team_api_id" AS "team_api_id",
        M."league_id",
        M."country_id",
        CASE
            WHEN M."away_team_goal" > M."home_team_goal" THEN 3
            WHEN M."away_team_goal" = M."home_team_goal" THEN 1
            ELSE 0
        END AS "points"
    FROM EU_SOCCER.EU_SOCCER.MATCH M
),
total_points_per_team AS (
    SELECT
        "season",
        "team_api_id",
        "league_id",
        "country_id",
        SUM("points") AS "total_points"
    FROM points_per_match
    GROUP BY "season", "team_api_id", "league_id", "country_id"
),
ranked_teams AS (
    SELECT
        tppt.*,
        ROW_NUMBER() OVER (PARTITION BY "season" ORDER BY "total_points" DESC NULLS LAST) AS rn
    FROM total_points_per_team tppt
)
SELECT
    tppt."season" AS "Season",
    t."team_long_name" AS "Team_Name",
    l."name" AS "League_Name",
    c."name" AS "Country_Name",
    tppt."total_points" AS "Total_Points"
FROM ranked_teams tppt
JOIN EU_SOCCER.EU_SOCCER.TEAM t ON tppt."team_api_id" = t."team_api_id"
JOIN EU_SOCCER.EU_SOCCER.LEAGUE l ON tppt."league_id" = l."id"
JOIN EU_SOCCER.EU_SOCCER.COUNTRY c ON tppt."country_id" = c."id"
WHERE tppt.rn = 1
ORDER BY tppt."season";