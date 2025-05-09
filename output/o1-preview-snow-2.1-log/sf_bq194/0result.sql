WITH py_modules AS (
    SELECT
        REGEXP_SUBSTR(l.value, '^[[:space:]]*(from|import)[[:space:]]+([a-zA-Z0-9_\.]+)', 1,1,'i',2) AS "module_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
        , LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) l
    WHERE sc."sample_path" ILIKE '%.py' 
        AND sc."content" ILIKE '%import%'
),
r_modules AS (
    SELECT
        REGEXP_SUBSTR(l.value, '^[[:space:]]*(library|require)[[:space:]]*\\([[:space:]]*([a-zA-Z0-9_\.]+)', 1,1,'i',2) AS "module_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
        , LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) l
    WHERE sc."sample_path" ILIKE '%.R' 
        AND (sc."content" ILIKE '%library(%' OR sc."content" ILIKE '%require(%')
)
SELECT "module_name", "Frequency"
FROM (
    SELECT "module_name", COUNT(*) AS "Frequency",
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS rn
    FROM (
        SELECT "module_name" FROM py_modules WHERE "module_name" IS NOT NULL
        UNION ALL
        SELECT "module_name" FROM r_modules WHERE "module_name" IS NOT NULL
    )
    GROUP BY "module_name"
)
WHERE rn = 2;