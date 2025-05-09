SELECT t."market" || ' ' || t."name" AS "Team_Name", COUNT(*) AS "Times_Max_Wins"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_HISTORICAL_TEAMS_SEASONS" s
JOIN (
  SELECT "season", MAX("wins") AS "max_wins"
  FROM NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_HISTORICAL_TEAMS_SEASONS"
  WHERE "season" BETWEEN 1900 AND 2000
  GROUP BY "season"
) m ON s."season" = m."season" AND s."wins" = m."max_wins"
JOIN NCAA_BASKETBALL.NCAA_BASKETBALL."MBB_TEAMS" t ON s."team_code" = t."code_ncaa"
WHERE s."season" BETWEEN 1900 AND 2000
GROUP BY t."market", t."name"
ORDER BY "Times_Max_Wins" DESC NULLS LAST, "Team_Name"
LIMIT 5;