/* Top-5 most frequently referenced modules across Python imports/from statements
   and R library() calls, restricted to *.py and *.r files                                  */
SELECT
    "module",
    COUNT(*) AS "freq"
FROM (
        /* ---------- Python (.py) ---------- */
        SELECT
            /* keep only the part before the first dot in a dotted import path */
            SPLIT_PART(
                COALESCE(
                    REGEXP_SUBSTR(l."VALUE",
                                   'import\\s+([A-Za-z0-9_\\.]+)',
                                   1, 1, 'i', 1),
                    REGEXP_SUBSTR(l."VALUE",
                                   'from\\s+([A-Za-z0-9_\\.]+)',
                                   1, 1, 'i', 1)
                ),
            '.', 1) AS "module"
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
               LATERAL SPLIT_TO_TABLE(c."content", '\n') l
        WHERE  c."sample_path" ILIKE '%.py'
          AND (l."VALUE" ILIKE '%import %' OR l."VALUE" ILIKE '%from %')

        UNION ALL

        /* ---------- R (.r / .R) ------------ */
        SELECT
            REGEXP_SUBSTR(l."VALUE",
                          'library\\s*\\(\\s*([A-Za-z0-9_\\.]+)\\s*\\)',
                          1, 1, 'i', 1) AS "module"
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
               LATERAL SPLIT_TO_TABLE(c."content", '\n') l
        WHERE  c."sample_path" ILIKE '%.r'
          AND  l."VALUE" ILIKE '%library(%'
) AS all_modules
WHERE "module" IS NOT NULL
GROUP BY "module"
ORDER BY "freq" DESC NULLS LAST
LIMIT 5;