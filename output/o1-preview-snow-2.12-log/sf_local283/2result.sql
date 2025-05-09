WITH team_points AS (
    SELECT
        m."season",
        m."league_id",
        m."country_id",
        m."home_team_api_id" AS "team_api_id",
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
        m."country_id",
        m."away_team_api_id" AS "team_api_id",
        CASE
            WHEN m."away_team_goal" > m."home_team_goal" THEN 3
            WHEN m."away_team_goal" = m."home_team_goal" THEN 1
            ELSE 0
        END AS "points"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH" m
),
total_points AS (
    SELECT
        "season",
        "league_id",
        "country_id",
        "team_api_id",
        SUM("points") AS "total_points"
    FROM team_points
    GROUP BY
        "season",
        "league_id",
        "country_id",
        "team_api_id"
),
ranked_teams AS (
    SELECT
        tp.*,
        RANK() OVER (
            PARTITION BY tp."season", tp."league_id"
            ORDER BY tp."total_points" DESC NULLS LAST
        ) AS "rank"
    FROM total_points tp
)
SELECT
    rt."season" AS "Season",
    t."team_long_name" AS "Team_Name",
    l."name" AS "League_Name",
    c."name" AS "Country_Name",
    rt."total_points" AS "Total_Points"
FROM ranked_teams rt
JOIN "EU_SOCCER"."EU_SOCCER"."TEAM" t ON rt."team_api_id" = t."team_api_id"
JOIN "EU_SOCCER"."EU_SOCCER"."LEAGUE" l ON rt."league_id" = l."id"
JOIN "EU_SOCCER"."EU_SOCCER"."COUNTRY" c ON rt."country_id" = c."id"
WHERE rt."rank" = 1
ORDER BY rt."season", l."name";