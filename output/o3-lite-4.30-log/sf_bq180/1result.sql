WITH python_modules AS (
    SELECT LOWER(
               REGEXP_SUBSTR(
                   f.value::STRING,
                   '^[ \\t]*(from|import)[ \\t]+([A-Za-z0-9_\\.]+)',
                   1, 1, 'i', 2          -- capture group 2 = module name
               )
           ) AS module
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"    sf
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc
          ON sf."id" = sc."id",
         LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) f
    WHERE sf."path" ILIKE '%.py'
),
r_modules AS (
    SELECT LOWER(
               REGEXP_SUBSTR(
                   f.value::STRING,
                   '^[ \\t]*(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                   1, 1, 'i', 2
               )
           ) AS module
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"    sf
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc
          ON sf."id" = sc."id",
         LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) f
    WHERE sf."path" ILIKE '%.r'
)
SELECT
    module AS module_name,
    COUNT(*) AS module_frequency
FROM (
      SELECT module FROM python_modules
      UNION ALL
      SELECT module FROM r_modules
) all_modules
WHERE module IS NOT NULL
GROUP BY module
ORDER BY module_frequency DESC NULLS LAST, module_name
LIMIT 5;