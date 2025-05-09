SELECT
    category,
    COUNT(*) AS occurrences
FROM (
    SELECT
        CASE
            WHEN REGEXP_LIKE(f.value::string, '[ \t]$') THEN 'trailing'   -- ends with space or tab
            WHEN REGEXP_LIKE(f.value::string, '^ ')       THEN 'Space'      -- starts with a space
            ELSE 'Other'
        END AS category
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
         ,LATERAL FLATTEN(INPUT => SPLIT("content", '\n')) f               -- one row per line
)
GROUP BY category
ORDER BY category;