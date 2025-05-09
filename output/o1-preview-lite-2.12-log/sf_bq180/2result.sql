SELECT module_name, COUNT(*) AS usage_count
FROM (
    SELECT 
        LOWER(TRIM(SPLIT_PART(l.value::STRING, ' ', 2))) AS module_name
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES AS f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
      ON f."id" = c."id",
    LATERAL FLATTEN(input => SPLIT(c."content", '\n')) AS l
    WHERE f."path" ILIKE '%.py' AND l.value::STRING LIKE 'import %'

    UNION ALL

    SELECT 
        LOWER(TRIM(SPLIT_PART(SPLIT_PART(l.value::STRING, '(', 2), ')', 1))) AS module_name
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES AS f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
      ON f."id" = c."id",
    LATERAL FLATTEN(input => SPLIT(c."content", '\n')) AS l
    WHERE (f."path" ILIKE '%.r' OR f."path" ILIKE '%.R')
      AND (l.value::STRING LIKE '%library(%' OR l.value::STRING LIKE '%require(%')
) AS sub
WHERE module_name IS NOT NULL AND module_name <> ''
GROUP BY module_name
ORDER BY usage_count DESC NULLS LAST
LIMIT 5;