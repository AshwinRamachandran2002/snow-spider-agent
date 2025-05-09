/*  Champion (highest–point) team for every league in each season                               */
/*  3 points per win, 1 per draw, 0 per loss                                                     */
WITH match_points AS (      /* 2 rows per match – one for each team with its points            */
    SELECT
        "season",
        "league_id",
        "country_id",
        "home_team_api_id"          AS "team_api_id",
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN 3
            WHEN "home_team_goal" = "away_team_goal" THEN 1
            ELSE 0
        END                       AS "points"
    FROM EU_SOCCER.EU_SOCCER."MATCH"

    UNION ALL

    SELECT
        "season",
        "league_id",
        "country_id",
        "away_team_api_id"          AS "team_api_id",
        CASE
            WHEN "away_team_goal" > "home_team_goal" THEN 3
            WHEN "away_team_goal" = "home_team_goal" THEN 1
            ELSE 0
        END                       AS "points"
    FROM EU_SOCCER.EU_SOCCER."MATCH"
),

team_season_points AS (     /* aggregate points per team-league-season                         */
    SELECT
        "season",
        "league_id",
        "country_id",
        "team_api_id",
        SUM("points")  AS "total_points"
    FROM match_points
    GROUP BY
        "season",
        "league_id",
        "country_id",
        "team_api_id"
),

ranked AS (                 /* rank teams by points (tie-break: smaller team_api_id)           */
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY "season", "league_id"
            ORDER BY "total_points" DESC NULLS LAST,
                     "team_api_id"
        ) AS "rn"
    FROM team_season_points
)

SELECT
    r."season",
    t."team_long_name"       AS "team_name",
    l."name"                 AS "league_name",
    c."name"                 AS "country_name",
    r."total_points"
FROM ranked r
JOIN EU_SOCCER.EU_SOCCER."TEAM"    t ON t."team_api_id" = r."team_api_id"
JOIN EU_SOCCER.EU_SOCCER."LEAGUE"  l ON l."id"         = r."league_id"
JOIN EU_SOCCER.EU_SOCCER."COUNTRY" c ON c."id"         = l."country_id"
WHERE r."rn" = 1                    -- champions only
ORDER BY
    r."season",
    l."name";