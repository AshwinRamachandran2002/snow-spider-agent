WITH wins_per_team AS (
    SELECT
        m."league_id",
        CASE
            WHEN m."home_team_goal" > m."away_team_goal" THEN m."home_team_api_id"
            WHEN m."away_team_goal" > m."home_team_goal" THEN m."away_team_api_id"
            ELSE NULL
        END AS team_api_id,
        COUNT(*) AS wins
    FROM "Match" m
    WHERE m."home_team_goal" != m."away_team_goal"
    GROUP BY m."league_id", team_api_id
),
min_wins_per_league AS (
    SELECT
        wpt."league_id",
        MIN(wpt."wins") AS min_wins
    FROM wins_per_team wpt
    WHERE wpt."team_api_id" IS NOT NULL
    GROUP BY wpt."league_id"
),
teams_with_min_wins AS (
    SELECT wpt.*
    FROM wins_per_team wpt
    JOIN min_wins_per_league mwpl ON wpt."league_id" = mwpl."league_id"
        AND wpt."wins" = mwpl."min_wins"
),
selected_teams AS (
    SELECT
        twmw."league_id",
        MIN(twmw."team_api_id") AS team_api_id -- Select one team with the lowest team_api_id in case of ties
    FROM teams_with_min_wins twmw
    GROUP BY twmw."league_id"
)
SELECT
    l."id" AS league_id,
    l."name" AS league_name,
    t."team_api_id" AS team_id,
    t."team_long_name",
    wpt."wins"
FROM selected_teams st
JOIN wins_per_team wpt ON st."league_id" = wpt."league_id" AND st."team_api_id" = wpt."team_api_id"
JOIN "Team" t ON st."team_api_id" = t."team_api_id"
JOIN "League" l ON st."league_id" = l."id"
ORDER BY l."id";