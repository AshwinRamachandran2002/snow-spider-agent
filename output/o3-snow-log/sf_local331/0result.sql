WITH seq AS (
    SELECT
        "session",
        "path",
        TO_TIMESTAMP_NTZ("stamp")                    AS ts,
        LAG("path")  OVER (PARTITION BY "session"
                          ORDER BY TO_TIMESTAMP_NTZ("stamp")) AS prev_path,
        LEAD("path") OVER (PARTITION BY "session"
                          ORDER BY TO_TIMESTAMP_NTZ("stamp")) AS next_path
    FROM LOG.LOG.ACTIVITY_LOG
),
third_visits AS (
    /* pick the record that is the 2nd consecutive '/detail/' visit
       and grab the very next path (= third page) */
    SELECT
        next_path AS third_page_path
    FROM seq
    WHERE "path"    = '/detail/'
      AND prev_path = '/detail/'
      AND next_path IS NOT NULL
)
SELECT
    third_page_path,
    COUNT(*) AS visit_count
FROM third_visits
GROUP BY third_page_path
ORDER BY visit_count DESC NULLS LAST
LIMIT 3;