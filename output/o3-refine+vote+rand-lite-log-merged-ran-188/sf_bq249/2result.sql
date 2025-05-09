WITH "LINES" AS (
    SELECT
        CASE
            WHEN RIGHT("VALUE", 1) = ' ' THEN 'trailing'           -- ends with a blank space
            WHEN LEFT("VALUE", 1)  = ' ' THEN 'Space'              -- starts with a blank space
            ELSE 'Other'
        END                                                       AS "LINE_TYPE"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS,
         LATERAL SPLIT_TO_TABLE("content", '\n')                  -- one row per line
)
SELECT
    "LINE_TYPE",
    COUNT(*) AS "OCCURRENCES"
FROM "LINES"
GROUP BY "LINE_TYPE"
ORDER BY "LINE_TYPE";