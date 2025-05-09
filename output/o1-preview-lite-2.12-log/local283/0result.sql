WITH team_results AS (
    SELECT
        "season",
        "home_team_api_id" AS team_api_id,
        "match_api_id",
        CASE
            WHEN "home_team_goal" > "away_team_goal" THEN 'win'
            WHEN "home_team_goal" = "away_team_goal" THEN 'tie'
            ELSE 'loss'
        END AS result,
        "league_id"
    FROM "Match"
    UNION ALL
    SELECT
        "season",
        "away_team_api_id" AS team_api_id,
        "match_api_id",
        CASE
            WHEN "away_team_goal" > "home_team_goal" THEN 'win'
            WHEN "away_team_goal" = "home_team_goal" THEN 'tie'
            ELSE 'loss'
        END AS result,
        "league_id"
    FROM "Match"
),
team_season_points AS (
    SELECT
        season,
        team_api_id,
        SUM(
            CASE
                WHEN result = 'win' THEN 3
                WHEN result = 'tie' THEN 1
                ELSE 0
            END
        ) AS total_points
    FROM team_results
    GROUP BY season, team_api_id
),
season_max_points AS (
    SELECT
        season,
        MAX(total_points) AS max_points
    FROM team_season_points
    GROUP BY season
),
season_champions AS (
    SELECT
        tsp.season,
        tsp.team_api_id,
        tsp.total_points
    FROM team_season_points tsp
    JOIN season_max_points smp
      ON tsp.season = smp.season AND tsp.total_points = smp.max_points
),
team_season_leagues AS (
    SELECT
        season,
        team_api_id,
        league_id,
        COUNT(*) AS matches_played
    FROM team_results
    GROUP BY season, team_api_id, league_id
),
max_team_league_matches AS (
    SELECT
        season,
        team_api_id,
        MAX(matches_played) AS max_matches_played
    FROM team_season_leagues
    GROUP BY season, team_api_id
),
team_primary_league AS (
    SELECT
        tsl.season,
        tsl.team_api_id,
        tsl.league_id
    FROM team_season_leagues tsl
    JOIN max_team_league_matches mtlm
      ON tsl.season = mtlm.season
     AND tsl.team_api_id = mtlm.team_api_id
     AND tsl.matches_played = mtlm.max_matches_played
),
champion_details AS (
    SELECT
        sc.season AS Season,
        t."team_long_name" AS Champion_Team_Name,
        l."name" AS League,
        c."name" AS Country,
        sc.total_points AS Total_Points
    FROM season_champions sc
    JOIN team_primary_league tpl
      ON sc.season = tpl.season
     AND sc.team_api_id = tpl.team_api_id
    JOIN "League" l ON tpl.league_id = l.id
    JOIN "Country" c ON l.country_id = c.id
    JOIN "Team" t ON sc.team_api_id = t.team_api_id
)
SELECT
    Season,
    Champion_Team_Name,
    League,
    Country,
    Total_Points
FROM champion_details
ORDER BY Season;