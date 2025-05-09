WITH ordered_actions AS (
    SELECT
        "session",
        "stamp",
        "path",
        ROW_NUMBER() OVER (PARTITION BY "session" ORDER BY "stamp") AS rn
    FROM
        "activity_log"
)
SELECT
    oa3."path" AS "Third_Action",
    COUNT(*) AS "Occurrence_Count"
FROM
    ordered_actions oa1
    JOIN ordered_actions oa2 ON oa1."session" = oa2."session" AND oa2.rn = oa1.rn + 1
    JOIN ordered_actions oa3 ON oa1."session" = oa3."session" AND oa3.rn = oa1.rn + 2
WHERE
    (oa1."path" = '/detail' OR oa1."path" = '/detail/') AND
    (oa2."path" = '/detail' OR oa2."path" = '/detail/')
GROUP BY
    oa3."path"
ORDER BY
    "Occurrence_Count" DESC
LIMIT 3;