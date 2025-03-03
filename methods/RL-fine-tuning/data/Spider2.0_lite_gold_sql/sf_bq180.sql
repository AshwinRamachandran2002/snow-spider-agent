WITH python_modules AS (
    SELECT
        LOWER(
            CASE
                WHEN REGEXP_SUBSTR("line", '^\\s*import\\s+(\\w+)', 1, 1, 'e', 1) IS NOT NULL THEN
                    REGEXP_SUBSTR("line", '^\\s*import\\s+(\\w+)', 1, 1, 'e', 1)
                WHEN REGEXP_SUBSTR("line", '^\\s*from\\s+(\\w+)\\s+import\\s+', 1, 1, 'e', 1) IS NOT NULL THEN
                    REGEXP_SUBSTR("line", '^\\s*from\\s+(\\w+)\\s+import\\s+', 1, 1, 'e', 1)
                ELSE NULL
            END
        ) AS "Module_Name"
    FROM (
        SELECT t.VALUE AS "line"
        FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS",
            LATERAL FLATTEN(INPUT => SPLIT("content", '\\n')) AS t
        WHERE "sample_path" ILIKE '%.py'
    )
    WHERE "line" ILIKE 'import %' OR "line" ILIKE 'from % import %'
), r_modules AS (
    SELECT LOWER(REGEXP_SUBSTR("line", 'library\\(([^)]+)\\)', 1, 1, 'e', 1)) AS "Module_Name"
    FROM (
        SELECT t.VALUE AS "line"
        FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS",
             LATERAL FLATTEN(INPUT => SPLIT("content", '\\n')) AS t
        WHERE "sample_path" ILIKE '%.R'
    )
    WHERE "line" ILIKE '%library(%'
    UNION ALL
    SELECT LOWER(REGEXP_SUBSTR("line", 'require\\(([^)]+)\\)', 1, 1, 'e', 1)) AS "Module_Name"
    FROM (
        SELECT t.VALUE AS "line"
        FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS",
            LATERAL FLATTEN(INPUT => SPLIT("content", '\\n')) AS t
        WHERE "sample_path" ILIKE '%.R'
    )
    WHERE "line" ILIKE '%require(%'
)
SELECT "Module_Name", COUNT(*) AS "Usage_Count"
FROM (
    SELECT "Module_Name" FROM python_modules
    UNION ALL
    SELECT "Module_Name" FROM r_modules
)
WHERE "Module_Name" IS NOT NULL
GROUP BY "Module_Name"
ORDER BY "Usage_Count" DESC NULLS LAST
LIMIT 5;