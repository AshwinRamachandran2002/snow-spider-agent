/*----------------------------------------------------------
  Champion team (highest points = 3/win, 1/draw, 0/loss)
  for every league and season, together with the league and
  country names and the total points obtained.
----------------------------------------------------------*/
WITH team_points AS (              -- 1.  points per match & side
    SELECT 
        "season",
        "league_id",
        "home_team_api_id"        AS team_api_id,
        CASE
             WHEN "home_team_goal" >  "away_team_goal" THEN 3
             WHEN "home_team_goal" =  "away_team_goal" THEN 1
             ELSE 0
        END                       AS points
    FROM EU_SOCCER.EU_SOCCER."MATCH"
    
    UNION ALL
    
    SELECT 
        "season",
        "league_id",
        "away_team_api_id"        AS team_api_id,
        CASE
             WHEN "away_team_goal" >  "home_team_goal" THEN 3
             WHEN "home_team_goal" =  "away_team_goal" THEN 1
             ELSE 0
        END                       AS points
    FROM EU_SOCCER.EU_SOCCER."MATCH"
),

season_team_points AS (            -- 2.  aggregate points per season-league-team
    SELECT
        "season",
        "league_id",
        team_api_id,
        SUM(points)               AS total_points
    FROM team_points
    GROUP BY "season", "league_id", team_api_id
),

season_champions AS (              -- 3.  choose champion (max points) per season-league
    SELECT
        stp.*,
        ROW_NUMBER() OVER (PARTITION BY "season", "league_id"
                           ORDER BY total_points DESC, team_api_id) AS rn
    FROM season_team_points stp
)

SELECT                              -- 4.  enrich with names, keep champions only
    t."team_long_name"  AS team_name,
    l."name"            AS league_name,
    c."name"            AS country_name,
    sc."season",
    sc.total_points
FROM season_champions sc
JOIN EU_SOCCER.EU_SOCCER.TEAM    t ON sc.team_api_id = t."team_api_id"
JOIN EU_SOCCER.EU_SOCCER.LEAGUE  l ON sc."league_id" = l."id"
JOIN EU_SOCCER.EU_SOCCER.COUNTRY c ON l."country_id" = c."id"
WHERE sc.rn = 1                    -- keep only champions
ORDER BY
    sc."season",
    league_name,
    team_name;