WITH file_content AS (
    SELECT f."path",
           c."content"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
           ON f."id" = c."id"
    WHERE  (f."path" ILIKE '%.py' OR f."path" ILIKE '%.r')
),
lines AS (
    SELECT fc."path",
           l.VALUE::STRING AS line
    FROM   file_content fc,
           LATERAL FLATTEN(INPUT => SPLIT(fc."content", '\n')) l
),
python_modules AS (
    SELECT LOWER(
             REGEXP_SUBSTR(
               line,
               '^\\s*(from|import)\\s+([A-Za-z0-9_]+)',
               1, 1, 'e', 2)
           ) AS module_name
    FROM   lines
    WHERE  "path" ILIKE '%.py'
      AND (line ILIKE 'import %' OR line ILIKE 'from %')
      AND REGEXP_SUBSTR(
            line,
            '^\\s*(from|import)\\s+([A-Za-z0-9_]+)',
            1, 1, 'e', 2) IS NOT NULL
),
r_packages AS (
    SELECT LOWER(
             REGEXP_SUBSTR(
               line,
               'library\\s*\\(\\s*[\'"]?([A-Za-z0-9_]+)',
               1, 1, 'e', 1)
           ) AS module_name
    FROM   lines
    WHERE  "path" ILIKE '%.r'
      AND line ILIKE 'library(%'
      AND REGEXP_SUBSTR(
            line,
            'library\\s*\\(\\s*[\'"]?([A-Za-z0-9_]+)',
            1, 1, 'e', 1) IS NOT NULL
)
SELECT module_name,
       COUNT(*) AS module_frequency
FROM   (
        SELECT module_name FROM python_modules
        UNION ALL
        SELECT module_name FROM r_packages
       )
GROUP  BY module_name
ORDER  BY module_frequency DESC NULLS LAST,
         module_name
LIMIT 5;