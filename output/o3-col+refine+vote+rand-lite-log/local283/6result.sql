WITH points AS (
    /* 1.  Points earned by every team in every match (home + away) */
    SELECT 
        "season",
        "league_id",
        "home_team_api_id"                    AS team_api_id,
        CASE 
            WHEN "home_team_goal" > "away_team_goal" THEN 3
            WHEN "home_team_goal" = "away_team_goal" THEN 1
            ELSE 0 
        END                                   AS pts
    FROM   "Match"
    
    UNION ALL
    
    SELECT 
        "season",
        "league_id",
        "away_team_api_id",
        CASE 
            WHEN "away_team_goal" > "home_team_goal" THEN 3
            WHEN "home_team_goal" = "away_team_goal" THEN 1
            ELSE 0 
        END
    FROM   "Match"
),
team_season_points AS (
    /* 2.  Total points per team, season & league */
    SELECT 
        "season",
        "league_id",
        team_api_id,
        SUM(pts)                              AS total_points
    FROM   points
    GROUP BY 
        "season",
        "league_id",
        team_api_id
),
max_pts AS (
    /* 3.  Maximum points achieved in every league-season */
    SELECT 
        "season",
        "league_id",
        MAX(total_points)                     AS top_points
    FROM   team_season_points
    GROUP BY 
        "season",
        "league_id"
)
 /* 4.  Retrieve the champion team(s) for every league and season,
        together with league & country names */
SELECT  
    tsp."season",
    t."team_long_name"                       AS champion_team,
    l."name"                                 AS league,
    c."name"                                 AS country,
    tsp.total_points                         AS points
FROM            team_season_points tsp
JOIN            max_pts            mp
       ON       tsp."season"      = mp."season"
       AND      tsp."league_id"   = mp."league_id"
       AND      tsp.total_points  = mp.top_points
JOIN            "Team"    t ON tsp.team_api_id = t.team_api_id
JOIN            "League"  l ON tsp."league_id" = l.id
JOIN            "Country" c ON l.country_id    = c.id
ORDER BY 
    tsp."season",
    l."name",
    champion_team;