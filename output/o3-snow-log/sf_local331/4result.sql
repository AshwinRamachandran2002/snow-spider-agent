/* +---------------------------------------------------------------------+
   |  Top-3 pages that appear immediately after two consecutive visits   |
   |  to “/detail/” (third-page visits) and their occurrence counts      |
   +---------------------------------------------------------------------+ */
WITH ordered_log AS (      -- events ordered inside each session
    SELECT
        "session",
        "path",
        TO_TIMESTAMP("stamp", 'YYYY-MM-DD HH24:MI:SS')      AS ts,
        LAG("path", 1) OVER (PARTITION BY "session"
                             ORDER BY TO_TIMESTAMP("stamp", 'YYYY-MM-DD HH24:MI:SS')) AS prev1_path,
        LAG("path", 2) OVER (PARTITION BY "session"
                             ORDER BY TO_TIMESTAMP("stamp", 'YYYY-MM-DD HH24:MI:SS')) AS prev2_path
    FROM LOG.LOG.ACTIVITY_LOG
),
third_page_candidates AS (  -- keep only the third pages
    SELECT
        "path" AS third_page
    FROM ordered_log
    WHERE prev1_path = '/detail/'
      AND prev2_path = '/detail/'
)
SELECT
    third_page                  AS "third_page",
    COUNT(*)                    AS "occurrences"
FROM third_page_candidates
GROUP BY third_page
ORDER BY "occurrences" DESC NULLS LAST
LIMIT 3;