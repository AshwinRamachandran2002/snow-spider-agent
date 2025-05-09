WITH team_points AS (
  SELECT
    "season",
    "league_id",
    "country_id",
    "team_api_id",
    SUM("points") AS "total_points"
  FROM (
    SELECT
      "season",
      "league_id",
      "country_id",
      "home_team_api_id" AS "team_api_id",
      CASE
        WHEN "home_team_goal" > "away_team_goal" THEN 3
        WHEN "home_team_goal" = "away_team_goal" THEN 1
        ELSE 0
      END AS "points"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
    UNION ALL
    SELECT
      "season",
      "league_id",
      "country_id",
      "away_team_api_id" AS "team_api_id",
      CASE
        WHEN "away_team_goal" > "home_team_goal" THEN 3
        WHEN "home_team_goal" = "away_team_goal" THEN 1
        ELSE 0
      END AS "points"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
  ) AS match_points
  GROUP BY
    "season",
    "league_id",
    "country_id",
    "team_api_id"
),
ranked_team_points AS (
  SELECT
    "season",
    "league_id",
    "country_id",
    "team_api_id",
    "total_points",
    RANK() OVER (
      PARTITION BY "season", "league_id"
      ORDER BY "total_points" DESC NULLS LAST
    ) AS "rank"
  FROM team_points
)
SELECT
  t."season" AS "Season",
  tm."team_long_name" AS "Team_Name",
  lg."name" AS "League_Name",
  c."name" AS "Country_Name",
  t."total_points" AS "Total_Points"
FROM ranked_team_points t
JOIN "EU_SOCCER"."EU_SOCCER"."TEAM" tm ON t."team_api_id" = tm."team_api_id"
JOIN "EU_SOCCER"."EU_SOCCER"."LEAGUE" lg ON t."league_id" = lg."id"
JOIN "EU_SOCCER"."EU_SOCCER"."COUNTRY" c ON t."country_id" = c."id"
WHERE t."rank" = 1
ORDER BY "Season", "League_Name";