WITH line_classification AS (
    SELECT
        CASE
            WHEN REGEXP_LIKE(line, '^ ')                       THEN 'Space'      -- starts with a space
            WHEN REGEXP_LIKE(line, '[ \t]$')                   THEN 'trailing'   -- ends with space or tab
            ELSE 'Other'                                                       -- all remaining lines
        END                           AS "line_type"
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS",
         LATERAL FLATTEN(INPUT => SPLIT("content", '\n')) f(line)
)
SELECT
    "line_type",
    COUNT(*) AS "occurrences"
FROM line_classification
GROUP BY "line_type";