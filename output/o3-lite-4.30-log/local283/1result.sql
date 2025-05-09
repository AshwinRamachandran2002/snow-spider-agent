WITH match_points AS (
    SELECT season,
           league_id,
           home_team_api_id AS team_api_id,
           CASE
               WHEN home_team_goal > away_team_goal THEN 3
               WHEN home_team_goal = away_team_goal THEN 1
               ELSE 0
           END AS points
    FROM "Match"
    UNION ALL
    SELECT season,
           league_id,
           away_team_api_id,
           CASE
               WHEN away_team_goal > home_team_goal THEN 3
               WHEN home_team_goal = away_team_goal THEN 1
               ELSE 0
           END
    FROM "Match"
),
team_season_points AS (
    SELECT  season,
            league_id,
            team_api_id,
            SUM(points) AS total_points
    FROM match_points
    GROUP BY season, league_id, team_api_id
),
max_points AS (
    SELECT  season,
            league_id,
            MAX(total_points) AS max_total
    FROM team_season_points
    GROUP BY season, league_id
),
champions AS (
    SELECT t.*
    FROM team_season_points t
    JOIN max_points m
      ON t.season        = m.season
     AND t.league_id     = m.league_id
     AND t.total_points  = m.max_total
)
SELECT  champions.season              AS season,
        Team.team_long_name           AS team,
        League.name                   AS league,
        Country.name                  AS country,
        champions.total_points        AS total_points
FROM champions
JOIN Team    ON Team.team_api_id = champions.team_api_id
JOIN League  ON League.id        = champions.league_id
JOIN Country ON Country.id       = League.country_id
ORDER BY champions.season,
         country,
         league,
         team;