/*  Champion team for every season (the team with the highest points
    among all leagues & countries that season) together with its league,
    country and total points.                                          */

WITH match_points AS (              -- give 3 / 1 / 0 points per match
    SELECT "season",
           "league_id",
           "home_team_api_id"  AS team_api_id,
           CASE
               WHEN "home_team_goal"  > "away_team_goal" THEN 3
               WHEN "home_team_goal"  = "away_team_goal" THEN 1
               ELSE 0
           END                 AS points
    FROM   "Match"

    UNION ALL

    SELECT "season",
           "league_id",
           "away_team_api_id"  AS team_api_id,
           CASE
               WHEN "away_team_goal"  > "home_team_goal" THEN 3
               WHEN "away_team_goal"  = "home_team_goal" THEN 1
               ELSE 0
           END                 AS points
    FROM   "Match"
),

/* total points per team, per season, per league */
season_team_points AS (
    SELECT  "season",
            "league_id",
            "team_api_id",
            SUM(points)        AS total_points
    FROM    match_points
    GROUP BY "season", "league_id", "team_api_id"
),

/* champion(s) of every league for every season */
league_champions AS (
    SELECT  stp.*
    FROM    season_team_points AS stp
    JOIN   (SELECT "season",
                   "league_id",
                   MAX(total_points) AS max_pts
            FROM   season_team_points
            GROUP BY "season", "league_id") AS mx
           ON  stp."season"       = mx."season"
           AND stp."league_id"    = mx."league_id"
           AND stp."total_points" = mx."max_pts"
),

/* best points tally across all leagues in each season */
season_best AS (
    SELECT  "season",
            MAX(total_points) AS best_pts
    FROM    league_champions
    GROUP BY "season"
)

/* final result: global champion(s) per season */
SELECT  lc."season"                               AS season,
        t."team_long_name"                        AS champion_team,
        l."name"                                  AS league,
        c."name"                                  AS country,
        lc."total_points"                         AS points
FROM    league_champions   AS lc
JOIN    season_best        AS sb
       ON lc."season"       = sb."season"
      AND lc."total_points" = sb."best_pts"
JOIN    "Team"             AS t  ON t."team_api_id" = lc."team_api_id"
JOIN    "League"           AS l  ON l."id"          = lc."league_id"
JOIN    "Country"          AS c  ON c."id"          = l."country_id"
ORDER BY lc."season", champion_team;