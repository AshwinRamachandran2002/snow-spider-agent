SELECT 
       module                             AS module_name,
       CAST(COUNT(*) AS NUMBER(38,4))     AS module_frequency
FROM (
        /* ---------- Python (.py) ---------- */
        SELECT REGEXP_SUBSTR(c."content",
                             '\\b(import|from)\\s+([A-Za-z_][A-Za-z0-9_\\.]*)',
                             1, 1, 'e', 2) AS module
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
        JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
               ON c."id" = f."id"
        WHERE  f."path" ILIKE '%.py'

        UNION ALL

        /* ---------- R (.r) ---------- */
        SELECT REGEXP_SUBSTR(c."content",
                             '\\b(library|require)\\s*\\(\\s*["'']?([A-Za-z0-9_\\.]+)',
                             1, 1, 'e', 2) AS module
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
        JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
               ON c."id" = f."id"
        WHERE  f."path" ILIKE '%.r'
     ) modules
WHERE module IS NOT NULL
GROUP BY module
ORDER BY module_frequency DESC NULLS LAST,
         module_name
LIMIT 5;