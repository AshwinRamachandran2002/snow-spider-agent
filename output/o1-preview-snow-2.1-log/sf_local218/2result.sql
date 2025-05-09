SELECT
  CAST(MEDIAN("max_season_goals") AS NUMERIC(10,4)) AS "Median_Highest_Season_Goals"
FROM (
  SELECT
    "team_api_id",
    MAX("total_goals") AS "max_season_goals"
  FROM (
    SELECT
      "season",
      "team_api_id",
      SUM("goals") AS "total_goals"
    FROM (
      SELECT
        "season",
        "home_team_api_id" AS "team_api_id",
        "home_team_goal" AS "goals"
      FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
      UNION ALL
      SELECT
        "season",
        "away_team_api_id" AS "team_api_id",
        "away_team_goal" AS "goals"
      FROM "EU_SOCCER"."EU_SOCCER"."MATCH"
    ) AS all_goals
    GROUP BY "season", "team_api_id"
  ) AS team_season_goals
  GROUP BY "team_api_id"
) AS team_max_goals;