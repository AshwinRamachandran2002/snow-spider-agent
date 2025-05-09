SELECT
    t."team_long_name",
    totals."total_wins"
FROM (
    SELECT
        "team_api_id",
        SUM("wins") AS "total_wins"
    FROM (
        /* wins as the home team */
        SELECT
            m."home_team_api_id" AS "team_api_id",
            COUNT(*)             AS "wins"
        FROM "Match" m
        WHERE m."home_team_goal" > m."away_team_goal"
        GROUP BY m."home_team_api_id"

        UNION ALL

        /* wins as the away team */
        SELECT
            m."away_team_api_id",
            COUNT(*)             AS "wins"
        FROM "Match" m
        WHERE m."away_team_goal" > m."home_team_goal"
        GROUP BY m."away_team_api_id"
    ) win_list
    GROUP BY "team_api_id"
) totals
JOIN "Team" t
  ON t."team_api_id" = totals."team_api_id"
ORDER BY totals."total_wins" DESC
LIMIT 10;