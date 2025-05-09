WITH 
teams_in_league AS (
    SELECT DISTINCT
        m."league_id",
        l."name" AS "league_name",
        t."team_api_id",
        t."team_long_name"
    FROM
        EU_SOCCER.EU_SOCCER.MATCH m
    JOIN EU_SOCCER.EU_SOCCER.TEAM t
        ON t."team_api_id" = m."home_team_api_id" OR t."team_api_id" = m."away_team_api_id"
    JOIN EU_SOCCER.EU_SOCCER.LEAGUE l
        ON l."id" = m."league_id"
),
home_wins AS (
    SELECT
        m."league_id",
        m."home_team_api_id" AS "team_api_id",
        COUNT(*) AS "wins"
    FROM
        EU_SOCCER.EU_SOCCER.MATCH m
    WHERE
        m."home_team_goal" > m."away_team_goal"
    GROUP BY
        m."league_id", m."home_team_api_id"
),
away_wins AS (
    SELECT
        m."league_id",
        m."away_team_api_id" AS "team_api_id",
        COUNT(*) AS "wins"
    FROM
        EU_SOCCER.EU_SOCCER.MATCH m
    WHERE
        m."away_team_goal" > m."home_team_goal"
    GROUP BY
        m."league_id", m."away_team_api_id"
),
total_wins_per_team AS (
    SELECT "league_id", "team_api_id", SUM("wins") AS "total_wins"
    FROM (
        SELECT * FROM home_wins
        UNION ALL
        SELECT * FROM away_wins
    ) win_union
    GROUP BY "league_id", "team_api_id"
),
teams_with_wins AS (
    SELECT
        til."league_id",
        til."league_name",
        til."team_api_id",
        til."team_long_name",
        COALESCE(twpt."total_wins", 0) AS "total_wins"
    FROM
        teams_in_league til
    LEFT JOIN total_wins_per_team twpt
        ON til."league_id" = twpt."league_id" AND til."team_api_id" = twpt."team_api_id"
)
SELECT
    "league_name",
    "team_name",
    "total_wins"
FROM (
    SELECT
        tw."league_name",
        tw."team_long_name" AS "team_name",
        tw."total_wins",
        ROW_NUMBER() OVER (
            PARTITION BY tw."league_name"
            ORDER BY tw."total_wins" ASC, tw."team_long_name" ASC
        ) AS rn
    FROM
        teams_with_wins tw
) subquery
WHERE
    rn = 1
ORDER BY
    "league_name";