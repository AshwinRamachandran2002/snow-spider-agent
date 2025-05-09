WITH Team_Stats AS (
  SELECT
    team_api_id,
    season,
    league_id,
    SUM(points) AS total_points,
    SUM(goals_for) - SUM(goals_against) AS goal_difference,
    SUM(goals_for) AS goals_scored
  FROM (
    SELECT
      home_team_api_id AS team_api_id,
      season,
      league_id,
      CASE
        WHEN home_team_goal > away_team_goal THEN 3
        WHEN home_team_goal = away_team_goal THEN 1
        ELSE 0
      END AS points,
      home_team_goal AS goals_for,
      away_team_goal AS goals_against
    FROM "Match"
    UNION ALL
    SELECT
      away_team_api_id AS team_api_id,
      season,
      league_id,
      CASE
        WHEN away_team_goal > home_team_goal THEN 3
        WHEN away_team_goal = home_team_goal THEN 1
        ELSE 0
      END AS points,
      away_team_goal AS goals_for,
      home_team_goal AS goals_against
    FROM "Match"
  ) AS Team_Match_Points
  GROUP BY team_api_id, season, league_id
),
Max_Points AS (
  SELECT
    season,
    league_id,
    MAX(total_points) AS max_points
  FROM Team_Stats
  GROUP BY season, league_id
),
Teams_With_Max_Points AS (
  SELECT
    ts.team_api_id,
    ts.season,
    ts.league_id,
    ts.total_points,
    ts.goal_difference,
    ts.goals_scored
  FROM Team_Stats ts
  JOIN Max_Points mp ON ts.season = mp.season AND ts.league_id = mp.league_id AND ts.total_points = mp.max_points
),
Max_Goal_Difference AS (
  SELECT
    season,
    league_id,
    MAX(goal_difference) AS max_goal_difference
  FROM Teams_With_Max_Points
  GROUP BY season, league_id
),
Teams_With_Max_GD AS (
  SELECT
    tmp.team_api_id,
    tmp.season,
    tmp.league_id,
    tmp.total_points,
    tmp.goal_difference,
    tmp.goals_scored
  FROM Teams_With_Max_Points tmp
  JOIN Max_Goal_Difference mgd ON tmp.season = mgd.season AND tmp.league_id = mgd.league_id AND tmp.goal_difference = mgd.max_goal_difference
),
Max_Goals_Scored AS (
  SELECT
    season,
    league_id,
    MAX(goals_scored) AS max_goals_scored
  FROM Teams_With_Max_GD
  GROUP BY season, league_id
)
SELECT
  tmg.season AS "Season",
  Team.team_long_name AS "Team_Name",
  League.name AS "League_Name",
  Country.name AS "Country_Name",
  tmg.total_points AS "Total_Points"
FROM Teams_With_Max_GD tmg
JOIN Max_Goals_Scored mgs ON tmg.season = mgs.season AND tmg.league_id = mgs.league_id AND tmg.goals_scored = mgs.max_goals_scored
JOIN Team ON tmg.team_api_id = Team.team_api_id
JOIN League ON tmg.league_id = League.id
JOIN Country ON League.country_id = Country.id
ORDER BY tmg.season, League.name;