/* ──  Three most frequent “third-page” visits that follow two consecutive
        visits to ‘/detail/’, together with their occurrence counts ── */
SELECT
    "third_page_path"        AS "third_page",
    COUNT(*)                 AS "visit_cnt"
FROM (
    /* Detect rows whose two immediately-previous rows in the same session
       were both visits to “/detail/” (i.e., the third page in the pattern) */
    SELECT
        "session",
        "path" AS "third_page_path"
    FROM (
        SELECT
            "session",
            "path",
            LAG("path",1) OVER (PARTITION BY "session" ORDER BY "stamp") AS "prev1_path",
            LAG("path",2) OVER (PARTITION BY "session" ORDER BY "stamp") AS "prev2_path"
        FROM LOG.LOG.ACTIVITY_LOG
        WHERE "path" IS NOT NULL
    )
    WHERE "prev1_path" = '/detail/'
      AND "prev2_path" = '/detail/'
)
GROUP BY "third_page_path"
ORDER BY "visit_cnt" DESC NULLS LAST
LIMIT 3;