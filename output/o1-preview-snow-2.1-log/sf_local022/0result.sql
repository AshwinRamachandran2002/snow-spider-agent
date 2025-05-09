SELECT DISTINCT P."player_name" AS "striker_name"
FROM (
  SELECT
    BS."match_id",
    BB."striker",
    BB."team_batting",
    SUM(BS."runs_scored") AS "total_runs"
  FROM "IPL"."IPL"."BATSMAN_SCORED" BS
  JOIN "IPL"."IPL"."BALL_BY_BALL" BB
    ON BS."match_id" = BB."match_id"
    AND BS."innings_no" = BB."innings_no"
    AND BS."over_id" = BB."over_id"
    AND BS."ball_id" = BB."ball_id"
  GROUP BY BS."match_id", BB."striker", BB."team_batting"
  HAVING SUM(BS."runs_scored") >= 100
) AS T
JOIN "IPL"."IPL"."MATCH" M
  ON T."match_id" = M."match_id"
JOIN "IPL"."IPL"."PLAYER" P
  ON T."striker" = P."player_id"
WHERE T."team_batting" != M."match_winner";