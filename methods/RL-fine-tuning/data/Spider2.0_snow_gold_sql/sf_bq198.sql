SELECT ts."market" || ' ' || ts."name" AS "Team_Name", COUNT(*) AS "Times_Max_Wins"
FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS ts
JOIN (
    SELECT "season", MAX("wins") AS "max_wins"
    FROM NCAA_BASKETBALL.NCAA_BASKETBALL.MBB_HISTORICAL_TEAMS_SEASONS
    WHERE "season" BETWEEN 1900 AND 2000
    GROUP BY "season"
) mw ON ts."season" = mw."season" AND ts."wins" = mw."max_wins"
WHERE ts."season" BETWEEN 1900 AND 2000
GROUP BY ts."market", ts."name"
ORDER BY "Times_Max_Wins" DESC NULLS LAST, ts."market", ts."name"
LIMIT 5;