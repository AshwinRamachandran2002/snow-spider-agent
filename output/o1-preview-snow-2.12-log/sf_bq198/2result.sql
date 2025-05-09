SELECT
     t1."name" AS "Team_Name",
     COUNT(*) AS "Times_Max_Wins"
FROM "NCAA_BASKETBALL"."NCAA_BASKETBALL"."MBB_HISTORICAL_TEAMS_SEASONS" t1
INNER JOIN (
     SELECT "season", MAX("wins") AS "max_wins"
     FROM "NCAA_BASKETBALL"."NCAA_BASKETBALL"."MBB_HISTORICAL_TEAMS_SEASONS"
     WHERE "season" BETWEEN 1900 AND 2000
     GROUP BY "season"
) t2 ON t1."season" = t2."season" AND t1."wins" = t2."max_wins"
WHERE t1."season" BETWEEN 1900 AND 2000
  AND t1."name" IS NOT NULL
  AND t1."name" <> ''
GROUP BY t1."name"
ORDER BY "Times_Max_Wins" DESC NULLS LAST, t1."name" ASC
LIMIT 5;