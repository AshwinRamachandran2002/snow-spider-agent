SELECT
    sub."option" AS "Action",
    COUNT(*) AS "Occurrences"
FROM (
    SELECT
        "session",
        "stamp",
        "option",
        "path",
        LAG("path", 1) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev_path1,
        LAG("path", 2) OVER (PARTITION BY "session" ORDER BY "stamp") AS prev_path2
    FROM "LOG"."LOG"."ACTIVITY_LOG"
) sub
WHERE
    prev_path1 IN ('/detail', '/detail/') AND
    prev_path2 IN ('/detail', '/detail/') AND
    sub."option" IS NOT NULL AND sub."option" <> ''
GROUP BY
    sub."option"
ORDER BY
    "Occurrences" DESC NULLS LAST
LIMIT 3;