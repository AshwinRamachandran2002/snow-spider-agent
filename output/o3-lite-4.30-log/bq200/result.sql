WITH union_games AS (
  SELECT * FROM `bigquery-public-data.baseball.games_wide`
  UNION ALL
  SELECT * FROM `bigquery-public-data.baseball.games_post_wide`
),
pitcher_with_team AS (
  /* keep only pitches for which the pitcherId is actually listed
     on the corresponding club’s lineup / fielders for that game */
  SELECT
    /* team that the pitcher belongs to in this row */
    CASE
      WHEN pitcherId IN UNNEST(ARRAY[
        homeFielder1,homeFielder2,homeFielder3,homeFielder4,homeFielder5,homeFielder6,
        homeFielder7,homeFielder8,homeFielder9,homeFielder10,homeFielder11,homeFielder12,
        homeBatter1 ,homeBatter2 ,homeBatter3 ,homeBatter4 ,homeBatter5 ,homeBatter6,
        homeBatter7 ,homeBatter8 ,homeBatter9 ])
      THEN homeTeamId
      WHEN pitcherId IN UNNEST(ARRAY[
        awayFielder1,awayFielder2,awayFielder3,awayFielder4,awayFielder5,awayFielder6,
        awayFielder7,awayFielder8,awayFielder9,awayFielder10,awayFielder11,awayFielder12,
        awayBatter1 ,awayBatter2 ,awayBatter3 ,awayBatter4 ,awayBatter5 ,awayBatter6,
        awayBatter7 ,awayBatter8 ,awayBatter9 ])
      THEN awayTeamId
    END                                                   AS team_id,
    CASE
      WHEN pitcherId IN UNNEST(ARRAY[
        homeFielder1,homeFielder2,homeFielder3,homeFielder4,homeFielder5,homeFielder6,
        homeFielder7,homeFielder8,homeFielder9,homeFielder10,homeFielder11,homeFielder12,
        homeBatter1 ,homeBatter2 ,homeBatter3 ,homeBatter4 ,homeBatter5 ,homeBatter6,
        homeBatter7 ,homeBatter8 ,homeBatter9 ])
      THEN homeTeamName
      WHEN pitcherId IN UNNEST(ARRAY[
        awayFielder1,awayFielder2,awayFielder3,awayFielder4,awayFielder5,awayFielder6,
        awayFielder7,awayFielder8,awayFielder9,awayFielder10,awayFielder11,awayFielder12,
        awayBatter1 ,awayBatter2 ,awayBatter3 ,awayBatter4 ,awayBatter5 ,awayBatter6,
        awayBatter7 ,awayBatter8 ,awayBatter9 ])
      THEN awayTeamName
    END                                                   AS team_name,
    CONCAT(pitcherFirstName,' ',pitcherLastName)          AS pitcher_name,
    pitchSpeed                                            AS pitch_speed
  FROM union_games
  WHERE pitchSpeed BETWEEN 1 AND 125            -- keep only plausible, non‑zero speeds
),
team_pitcher_max AS (
  /* highest speed each pitcher has thrown for each club */
  SELECT
    team_id,
    team_name,
    pitcher_name,
    MAX(pitch_speed) AS max_speed
  FROM pitcher_with_team
  WHERE team_id IS NOT NULL
  GROUP BY team_id, team_name, pitcher_name
),
ranked AS (
  /* select the single fastest pitcher for every club */
  SELECT
    team_id,
    team_name,
    pitcher_name,
    max_speed,
    ROW_NUMBER() OVER (PARTITION BY team_id
                       ORDER BY max_speed DESC, pitcher_name) AS rn
  FROM team_pitcher_max
)
SELECT
  team_name                                     AS team,
  pitcher_name,
  ROUND(CAST(max_speed AS NUMERIC),4)           AS max_pitch_speed_mph
FROM ranked
WHERE rn = 1
ORDER BY team;