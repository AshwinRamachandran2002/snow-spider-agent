/* Top-10 most frequently imported Java packages (each file counted once) */
SELECT
  p.package_name,
  COUNT(DISTINCT CONCAT(c."sample_repo_name", '/', c."sample_path")) AS file_occurrences
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c,
     LATERAL SPLIT_TO_TABLE(c."content", '\n')                       AS l,
     LATERAL (
       SELECT LOWER(
                REGEXP_REPLACE(
                  REGEXP_SUBSTR(l.value,
                                 '^import\\s+([a-zA-Z0-9_\\.]+)', 1, 1, 'i', 1),
                  '\\.[^.]+$',
                  '')
             ) AS package_name
     )                                                               AS p
WHERE c."sample_path" ILIKE '%.java'   -- Java source files only
  AND l.value ILIKE 'import %'         -- import statements
  AND p.package_name IS NOT NULL       -- successful matches
GROUP BY p.package_name
ORDER BY file_occurrences DESC NULLS LAST
LIMIT 10;