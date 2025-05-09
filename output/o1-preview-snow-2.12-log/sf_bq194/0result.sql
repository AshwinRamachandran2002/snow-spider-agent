WITH imports AS (
    SELECT
        l.value::STRING AS "line"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
        ON f."id" = c."id",
    LATERAL FLATTEN(input => SPLIT(c."content", '\n')) l
    WHERE (
        LOWER(f."path") LIKE '%.py' 
        OR LOWER(f."path") LIKE '%.r'
        OR LOWER(f."path") LIKE '%.rmd'
        OR LOWER(f."path") LIKE '%.ipynb'
    )
    AND c."binary" = FALSE
    AND (
        l.value ILIKE 'import %' 
        OR l.value ILIKE 'from % import %' 
        OR l.value ILIKE '%library(%' 
        OR l.value ILIKE '%require(%'
    )
),
modules AS (
    SELECT
        CASE
            WHEN "line" ILIKE 'import %' THEN SPLIT(REGEXP_REPLACE("line", '^.*import\\s+', ''), ' ')[0]
            WHEN "line" ILIKE 'from % import %' THEN REGEXP_SUBSTR("line", 'from\\s+([\\w\\.]+)', 1, 1, 'i', 1)
            WHEN "line" ILIKE '%library(%' THEN REGEXP_SUBSTR("line", 'library\\(\\s*([\\w\\.]+)', 1, 1, 'i', 1)
            WHEN "line" ILIKE '%require(%' THEN REGEXP_SUBSTR("line", 'require\\(\\s*([\\w\\.]+)', 1, 1, 'i', 1)
        END AS "module_name"
    FROM imports
)
SELECT
    "module_name" AS "Library_or_Module"
FROM modules
WHERE "module_name" IS NOT NULL
GROUP BY "module_name"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 1 OFFSET 1;