WITH match_results AS (
    SELECT
        m."season",
        m."league_id",
        m."home_team_api_id" AS "team_api_id",
        (m."home_team_goal" - m."away_team_goal") AS "goal_difference",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN 3
            WHEN m."home_team_goal" = m."away_team_goal" THEN 1
            ELSE 0
        END AS "points"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH" m
    UNION ALL
    SELECT
        m."season",
        m."league_id",
        m."away_team_api_id" AS "team_api_id",
        (m."away_team_goal" - m."home_team_goal") AS "goal_difference",
        CASE
            WHEN m."away_team_goal" > m."home_team_goal" THEN 3
            WHEN m."away_team_goal" = m."home_team_goal" THEN 1
            ELSE 0
        END AS "points"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH" m
),
team_stats AS (
    SELECT
        "season",
        "league_id",
        "team_api_id",
        SUM("points") AS "total_points",
        SUM("goal_difference") AS "total_goal_difference"
    FROM match_results
    GROUP BY "season", "league_id", "team_api_id"
),
ranked_teams AS (
    SELECT
        ts."season",
        ts."league_id",
        ts."team_api_id",
        ts."total_points",
        ts."total_goal_difference",
        RANK() OVER (
            PARTITION BY ts."season", ts."league_id"
            ORDER BY ts."total_points" DESC NULLS LAST, ts."total_goal_difference" DESC NULLS LAST
        ) AS "rank"
    FROM team_stats ts
)
SELECT
    rt."season" AS "Season",
    l."name" AS "League_name",
    c."name" AS "Country_name",
    t."team_long_name" AS "Team_name",
    rt."total_points" AS "Total_points"
FROM ranked_teams rt
JOIN "EU_SOCCER"."EU_SOCCER"."TEAM" t ON rt."team_api_id" = t."team_api_id"
JOIN "EU_SOCCER"."EU_SOCCER"."LEAGUE" l ON rt."league_id" = l."id"
JOIN "EU_SOCCER"."EU_SOCCER"."COUNTRY" c ON l."country_id" = c."id"
WHERE rt."rank" = 1
ORDER BY "Season", l."name";