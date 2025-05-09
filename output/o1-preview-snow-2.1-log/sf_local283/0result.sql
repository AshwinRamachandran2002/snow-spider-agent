WITH TeamPoints AS (
    SELECT
        m."season",
        m."league_id",
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
        m."away_team_api_id" AS "team_api_id",
        CASE
            WHEN m."away_team_goal" > m."home_team_goal" THEN 3
            WHEN m."away_team_goal" = m."home_team_goal" THEN 1
            ELSE 0
        END AS "points"
    FROM "EU_SOCCER"."EU_SOCCER"."MATCH" m
),
TeamTotalPoints AS (
    SELECT
        tp."season",
        tp."league_id",
        tp."team_api_id",
        SUM(tp."points") AS "total_points"
    FROM TeamPoints tp
    GROUP BY tp."season", tp."league_id", tp."team_api_id"
),
RankedTeams AS (
    SELECT
        ttp.*,
        ROW_NUMBER() OVER (
            PARTITION BY ttp."season", ttp."league_id" 
            ORDER BY ttp."total_points" DESC NULLS LAST
        ) AS "rank"
    FROM TeamTotalPoints ttp
)
SELECT
    rt."season" AS "Season",
    l."name" AS "League_name",
    c."name" AS "Country_name",
    t."team_long_name" AS "Team_name",
    rt."total_points" AS "Total_points"
FROM RankedTeams rt
JOIN "EU_SOCCER"."EU_SOCCER"."TEAM" t ON rt."team_api_id" = t."team_api_id"
JOIN "EU_SOCCER"."EU_SOCCER"."LEAGUE" l ON rt."league_id" = l."id"
JOIN "EU_SOCCER"."EU_SOCCER"."COUNTRY" c ON l."country_id" = c."id"
WHERE rt."rank" = 1
ORDER BY rt."season", l."name";