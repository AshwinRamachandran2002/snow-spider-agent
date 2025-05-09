WITH player_matches AS (
  SELECT
    m."match_api_id",
    p.value::NUMBER AS "player_api_id",
    CASE
      WHEN m."home_team_goal" > m."away_team_goal" THEN 1
      ELSE 0
    END AS "win"
  FROM "EU_SOCCER"."EU_SOCCER"."MATCH" m,
  LATERAL FLATTEN (input => ARRAY_CONSTRUCT(
    m."home_player_1", m."home_player_2", m."home_player_3", m."home_player_4", m."home_player_5",
    m."home_player_6", m."home_player_7", m."home_player_8", m."home_player_9", m."home_player_10", m."home_player_11"
  )) p
  WHERE p.value IS NOT NULL

  UNION ALL

  SELECT
    m."match_api_id",
    p.value::NUMBER AS "player_api_id",
    CASE
      WHEN m."away_team_goal" > m."home_team_goal" THEN 1
      ELSE 0
    END AS "win"
  FROM "EU_SOCCER"."EU_SOCCER"."MATCH" m,
  LATERAL FLATTEN (input => ARRAY_CONSTRUCT(
    m."away_player_1", m."away_player_2", m."away_player_3", m."away_player_4", m."away_player_5",
    m."away_player_6", m."away_player_7", m."away_player_8", m."away_player_9", m."away_player_10", m."away_player_11"
  )) p
  WHERE p.value IS NOT NULL
)
SELECT
  p."player_name",
  SUM(pm."win") AS "number_of_wins"
FROM player_matches pm
JOIN "EU_SOCCER"."EU_SOCCER"."PLAYER" p
  ON p."player_api_id" = pm."player_api_id"
GROUP BY p."player_name"
ORDER BY "number_of_wins" DESC NULLS LAST
LIMIT 1;