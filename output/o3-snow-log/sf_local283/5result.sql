/*--------------------------------------------------------------------
  Champion team for every season (all countries & leagues combined)
  – 3 pts / win, 1 pt / draw, 0 pts / loss
--------------------------------------------------------------------*/
WITH "points_per_match" AS (            /* points earned by each team in every single match */
    /* Home teams */
    SELECT  "season",
            "home_team_api_id"      AS "team_api_id",
            "league_id",
            "country_id",
            CASE
                WHEN "home_team_goal" > "away_team_goal" THEN 3
                WHEN "home_team_goal" = "away_team_goal" THEN 1
                ELSE 0
            END                     AS "points"
    FROM    EU_SOCCER.EU_SOCCER.MATCH

    UNION ALL                       /* Away teams */
    SELECT  "season",
            "away_team_api_id"      AS "team_api_id",
            "league_id",
            "country_id",
            CASE
                WHEN "away_team_goal" > "home_team_goal" THEN 3
                WHEN "away_team_goal" = "home_team_goal" THEN 1
                ELSE 0
            END                     AS "points"
    FROM    EU_SOCCER.EU_SOCCER.MATCH
),

"season_team_points" AS (              /* total points a team collected in a season */
    SELECT  "season",
            "team_api_id",
            "league_id",
            "country_id",
            SUM("points")             AS "total_points"
    FROM    "points_per_match"
    GROUP BY
            "season",
            "team_api_id",
            "league_id",
            "country_id"
),

"season_champions" AS (                /* champion (highest total points) per season */
    SELECT  stp.*,
            ROW_NUMBER() OVER (PARTITION BY stp."season"
                               ORDER BY stp."total_points" DESC NULLS LAST,
                                        stp."team_api_id")  AS "rn"
    FROM    "season_team_points" stp
)

SELECT  sc."season",
        t."team_long_name"             AS "champion_team",
        l."name"                       AS "league",
        c."name"                       AS "country",
        sc."total_points"
FROM    "season_champions" sc
JOIN    EU_SOCCER.EU_SOCCER.TEAM     t  ON sc."team_api_id" = t."team_api_id"
JOIN    EU_SOCCER.EU_SOCCER.LEAGUE   l  ON sc."league_id"   = l."id"
JOIN    EU_SOCCER.EU_SOCCER.COUNTRY  c  ON sc."country_id"  = c."id"
WHERE   sc."rn" = 1                    -- keep only the champion of each season
ORDER BY sc."season" ASC;