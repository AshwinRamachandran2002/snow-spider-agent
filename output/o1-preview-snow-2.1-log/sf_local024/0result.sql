WITH CountryRuns AS (
  SELECT p."country_name", SUM(tr."total_runs") AS "Total_Runs"
  FROM (
    SELECT b."striker" AS "player_id", SUM(bs."runs_scored") AS "total_runs"
    FROM IPL.IPL."BALL_BY_BALL" b
    JOIN IPL.IPL."BATSMAN_SCORED" bs
      ON b."match_id" = bs."match_id"
      AND b."over_id" = bs."over_id"
      AND b."ball_id" = bs."ball_id"
      AND b."innings_no" = bs."innings_no"
    GROUP BY b."striker"
  ) tr
  JOIN IPL.IPL."PLAYER" p ON tr."player_id" = p."player_id"
  GROUP BY p."country_name"
),
CountryMatches AS (
  SELECT p."country_name", COUNT(*) AS "Total_Matches"
  FROM IPL.IPL."PLAYER_MATCH" pm
  JOIN IPL.IPL."PLAYER" p ON pm."player_id" = p."player_id"
  GROUP BY p."country_name"
),
CountryDismissals AS (
  SELECT p."country_name", SUM(td."dismissals") AS "Total_Dismissals"
  FROM (
    SELECT "player_out" AS "player_id", COUNT(*) AS "dismissals"
    FROM IPL.IPL."WICKET_TAKEN"
    GROUP BY "player_out"
  ) td
  JOIN IPL.IPL."PLAYER" p ON td."player_id" = p."player_id"
  GROUP BY p."country_name"
)
SELECT cr."country_name" AS "Country",
       ROUND(cr."Total_Runs" / cm."Total_Matches", 4) AS "Average_Runs_per_Match",
       ROUND(cr."Total_Runs" / cd."Total_Dismissals", 4) AS "Batting_Average"
FROM CountryRuns cr
JOIN CountryMatches cm ON cr."country_name" = cm."country_name"
JOIN CountryDismissals cd ON cr."country_name" = cd."country_name"
ORDER BY "Average_Runs_per_Match" DESC NULLS LAST
LIMIT 5;