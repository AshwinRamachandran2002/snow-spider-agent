WITH team_points AS (
    SELECT
        m."season",
        m."league_id",
        m."home_team_api_id" AS "team_api_id",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN 3
            WHEN m."home_team_goal" = m."away_team_goal" THEN 1
            ELSE 0
        END AS "points"
    FROM
        "EU_SOCCER"."EU_SOCCER"."MATCH" m
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
    FROM
        "EU_SOCCER"."EU_SOCCER"."MATCH" m
),
team_total_points AS (
    SELECT
        tp."season",
        tp."league_id",
        tp."team_api_id",
        SUM(tp."points") AS "total_points"
    FROM
        team_points tp
    GROUP BY
        tp."season",
        tp."league_id",
        tp."team_api_id"
),
ranked_teams AS (
    SELECT
        ttp.*,
        ROW_NUMBER() OVER (
            PARTITION BY ttp."season", ttp."league_id"
            ORDER BY ttp."total_points" DESC NULLS LAST, ttp."team_api_id" ASC
        ) AS "rn"
    FROM
        team_total_points ttp
)
SELECT
    ttp."season" AS "Season",
    l."name" AS "League_name",
    c."name" AS "Country_name",
    t."team_long_name" AS "Team_name",
    ttp."total_points" AS "Total_points"
FROM
    ranked_teams ttp
JOIN "EU_SOCCER"."EU_SOCCER"."TEAM" t
    ON ttp."team_api_id" = t."team_api_id"
JOIN "EU_SOCCER"."EU_SOCCER"."LEAGUE" l
    ON ttp."league_id" = l."id"
JOIN "EU_SOCCER"."EU_SOCCER"."COUNTRY" c
    ON l."country_id" = c."id"
WHERE
    ttp."rn" = 1
ORDER BY
    ttp."season" ASC,
    l."name" ASC;