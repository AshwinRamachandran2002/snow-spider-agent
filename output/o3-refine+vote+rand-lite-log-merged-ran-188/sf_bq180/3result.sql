/* Top-5 most frequently referenced Python & R modules/packages */
SELECT
       LOWER(module_name)       AS module_name,
       COUNT(*)                 AS occurrence_count
FROM (
        /* ---------- Python:  “import <module>” ---------------- */
        SELECT REGEXP_SUBSTR(f.value::STRING,
                             '^\\s*import\\s+([A-Za-z0-9_]+)',
                             1, 1, 'e', 1)   AS module_name
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  p,
               LATERAL FLATTEN (INPUT => SPLIT(p."content", '\n')) f
        WHERE  p."sample_path" ILIKE '%.py'

        UNION ALL

        /* ---------- Python:  “from <module> import …” ---------- */
        SELECT REGEXP_SUBSTR(f.value::STRING,
                             '^\\s*from\\s+([A-Za-z0-9_]+)',
                             1, 1, 'e', 1)   AS module_name
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  p,
               LATERAL FLATTEN (INPUT => SPLIT(p."content", '\n')) f
        WHERE  p."sample_path" ILIKE '%.py'

        UNION ALL

        /* ---------- R:  library(<package>) --------------------- */
        SELECT REGEXP_SUBSTR(f.value::STRING,
                             '\\blibrary\\s*\\(\\s*([A-Za-z0-9_.]+)',
                             1, 1, 'e', 1)   AS module_name
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  r,
               LATERAL FLATTEN (INPUT => SPLIT(r."content", '\n')) f
        WHERE  r."sample_path" ILIKE '%.r'
     ) AS modules
WHERE module_name IS NOT NULL
GROUP BY LOWER(module_name)
ORDER BY occurrence_count DESC NULLS LAST
LIMIT 5;