SELECT "Language", "Module_or_Library", COUNT(*) AS "Count"
FROM (
    -- Extract Python 'import' statements
    SELECT 'Python' AS "Language",
           REGEXP_SUBSTR(lines.value, '^\\s*import\\s+(\\w+)', 1, 1, 'i', 1) AS "Module_or_Library"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c ON f."id" = c."id",
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) AS lines
    WHERE f."path" LIKE '%.py' AND c."binary" = FALSE

    UNION ALL

    -- Extract Python 'from ... import' statements
    SELECT 'Python' AS "Language",
           REGEXP_SUBSTR(lines.value, '^\\s*from\\s+(\\w+)\\s+import\\b', 1, 1, 'i', 1) AS "Module_or_Library"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c ON f."id" = c."id",
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) AS lines
    WHERE f."path" LIKE '%.py' AND c."binary" = FALSE

    UNION ALL

    -- Extract R libraries
    SELECT 'R' AS "Language",
           REGEXP_SUBSTR(lines.value, '^\\s*library\\s*\\(\\s*(\\w+)\\s*\\)', 1, 1, 'i', 1) AS "Module_or_Library"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c ON f."id" = c."id",
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) AS lines
    WHERE f."path" LIKE '%.r' AND c."binary" = FALSE
) AS modules
WHERE "Module_or_Library" IS NOT NULL AND "Module_or_Library" <> ''
GROUP BY "Language", "Module_or_Library"
ORDER BY "Language", "Count" DESC NULLS LAST;