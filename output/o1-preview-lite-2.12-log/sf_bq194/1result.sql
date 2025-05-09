WITH code_lines AS (
    SELECT
        LOWER(l.VALUE::STRING) AS code_line
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
        ON f."id" = c."id",
    LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) l
    WHERE (f."path" ILIKE '%.py' OR f."path" ILIKE '%.r' OR f."path" ILIKE '%.ipynb')
        AND (
            l.VALUE::STRING LIKE 'import %' OR
            l.VALUE::STRING LIKE 'from %' OR
            l.VALUE::STRING LIKE 'library(%'
        )
        AND l.VALUE::STRING NOT LIKE '--%'  -- Exclude commented lines
        AND l.VALUE::STRING NOT LIKE '#%'   -- Exclude Python comments
        AND l.VALUE::STRING NOT LIKE 'import __future__%' -- Exclude special imports
        AND l.VALUE::STRING NOT LIKE 'from __future__%'   -- Exclude special imports
),
module_imports AS (
    SELECT
        REGEXP_SUBSTR(code_line, '^import\\s+(.*)', 1, 1, 'e') AS imports
    FROM code_lines
    WHERE code_line LIKE 'import %'
    UNION ALL
    SELECT
        REGEXP_SUBSTR(code_line, '^from\\s+([^\\s]+)', 1, 1, 'e') AS imports
    FROM code_lines
    WHERE code_line LIKE 'from %'
    UNION ALL
    SELECT
        REGEXP_SUBSTR(code_line, '^library\\s*\\(\\s*([^\\s\\)]+)', 1, 1, 'e') AS imports
    FROM code_lines
    WHERE code_line LIKE 'library(%'
),
split_modules AS (
    SELECT
        TRIM(REGEXP_SUBSTR(module_name, '^[^\\s]+')) AS "Module"
    FROM (
        SELECT
            TRIM(s.VALUE::STRING) AS module_name
        FROM module_imports,
        LATERAL FLATTEN(INPUT => SPLIT(imports, ',')) s
    )
)
SELECT "Module", COUNT(*) AS "Frequency"
FROM split_modules
WHERE "Module" IS NOT NULL AND "Module" <> ''
GROUP BY "Module"
ORDER BY "Frequency" DESC NULLS LAST
LIMIT 1 OFFSET 1;