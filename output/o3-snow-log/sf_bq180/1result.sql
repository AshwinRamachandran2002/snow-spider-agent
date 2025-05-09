/* Top-5 most frequent Python & R modules/packages */
SELECT module,
       COUNT(*) AS usage_count
FROM (
        /* ---------- Python: import / from ----------- */
        SELECT LOWER(
                 REGEXP_SUBSTR(ln.value::STRING,
                               '^[[:space:]]*(from|import)[[:space:]]+([A-Za-z0-9_\\.]+)',
                               1, 1, 'e', 2)      -- 2 = module name group
               ) AS module
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
               LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) ln
        WHERE  c."sample_path" ILIKE '%.py'

        UNION ALL

        /* -------------- R: library() ---------------- */
        SELECT LOWER(
                 REGEXP_SUBSTR(ln.value::STRING,
                               'library\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                               1, 1, 'e', 1)      -- 1 = package name group
               ) AS module
        FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
               LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) ln
        WHERE  c."sample_path" ILIKE '%.r'
     ) AS all_modules
WHERE  module IS NOT NULL
GROUP BY module
ORDER BY usage_count DESC NULLS LAST
LIMIT 5;