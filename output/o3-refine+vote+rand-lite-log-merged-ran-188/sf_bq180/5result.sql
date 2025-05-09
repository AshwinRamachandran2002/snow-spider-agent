WITH python_modules AS (
    SELECT
        LOWER(
            COALESCE(
                REGEXP_SUBSTR(line.value, 'import\\s+([A-Za-z0-9_\\.]+)', 1, 1, 'i', 1),
                REGEXP_SUBSTR(line.value, 'from\\s+([A-Za-z0-9_\\.]+)',   1, 1, 'i', 1)
            )
        ) AS module_name
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc,
         LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
    WHERE sc."sample_path" ILIKE '%.py'
      AND (line.value ILIKE 'import %' OR line.value ILIKE 'from %')
      AND module_name IS NOT NULL
), r_modules AS (
    SELECT
        LOWER(
            REGEXP_SUBSTR(line.value, 'library\\s*\\(([^)]+)\\)', 1, 1, 'i', 1)
        ) AS module_name
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc,
         LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
    WHERE sc."sample_path" ILIKE '%.r'
      AND line.value ILIKE '%library(%'
      AND module_name IS NOT NULL
)
SELECT
    module_name,
    COUNT(*) AS frequency
FROM (
    SELECT module_name FROM python_modules
    UNION ALL
    SELECT module_name FROM r_modules
)
GROUP BY module_name
ORDER BY frequency DESC NULLS LAST
LIMIT 5;