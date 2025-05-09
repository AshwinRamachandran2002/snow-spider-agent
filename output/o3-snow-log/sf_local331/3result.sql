/* ------------------------------------------------------------
   Find the three most frequent “third-page” visits that occur
   immediately after two consecutive visits to the “/detail”
   page (within the same session).
-------------------------------------------------------------*/
WITH ordered AS (
    /* 1.  Order every pageview inside each session chronologically */
    SELECT
        "session",
        "path",
        TO_TIMESTAMP_NTZ("stamp")      AS ts,
        ROW_NUMBER() OVER (
            PARTITION BY "session"
            ORDER BY TO_TIMESTAMP_NTZ("stamp")
        )                              AS rn
    FROM LOG.LOG.ACTIVITY_LOG
    WHERE "stamp" <> ''                -- ignore empty stamps
),
seq AS (
    /* 2.  Attach the two previous page paths to every row        */
    SELECT
        "session",
        rn,
        "path"                                                AS third_page,
        LAG("path", 1) OVER (PARTITION BY "session" ORDER BY rn) AS prev1,
        LAG("path", 2) OVER (PARTITION BY "session" ORDER BY rn) AS prev2
    FROM ordered
),
third_pages AS (
    /* 3.  Keep rows whose two immediate predecessors are /detail */
    SELECT
        third_page
    FROM seq
    WHERE prev1 LIKE '/detail%'      -- first predecessor
      AND prev2 LIKE '/detail%'      -- second predecessor
)
SELECT
    third_page,
    COUNT(*) AS occurrences
FROM third_pages
GROUP BY third_page
ORDER BY occurrences DESC NULLS LAST
LIMIT 3;