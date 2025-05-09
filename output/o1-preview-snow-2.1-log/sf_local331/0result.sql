SELECT "third_action" AS "Action", COUNT(*) AS "Occurrences"
FROM (
    SELECT "user_id", "session", "action",
        LAG("action", 2) OVER (
            PARTITION BY "user_id", "session" 
            ORDER BY TO_TIMESTAMP("stamp", 'YYYY-MM-DD HH24:MI:SS'), "action"
        ) AS "first_action",
        LAG("action", 1) OVER (
            PARTITION BY "user_id", "session" 
            ORDER BY TO_TIMESTAMP("stamp", 'YYYY-MM-DD HH24:MI:SS'), "action"
        ) AS "second_action",
        "action" AS "third_action"
    FROM LOG.LOG.ACTION_LOG
)
WHERE "first_action" = 'view' AND "second_action" = 'view'
GROUP BY "third_action"
ORDER BY "Occurrences" DESC
LIMIT 3;