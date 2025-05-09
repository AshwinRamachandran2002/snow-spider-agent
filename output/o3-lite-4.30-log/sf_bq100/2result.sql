WITH import_blocks AS (
    SELECT REGEXP_SUBSTR("content",
                         'import\\s*\\(([^)]*)\\)',
                         1, 1, 'e', 1) AS imports_block
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "content" ILIKE '%import (%'
      AND  "sample_path" ILIKE '%.go'
),
import_lines AS (
    SELECT TRIM(f.VALUE::STRING) AS import_line
    FROM   import_blocks,
           LATERAL FLATTEN(INPUT => SPLIT(imports_block, '\n')) f
),
packages AS (
    SELECT REGEXP_SUBSTR(import_line,
                         '"([^"]+)"',
                         1, 1, 'e', 1) AS package_name
    FROM   import_lines
    WHERE  import_line LIKE '%"%'
),
pkg_counts AS (
    SELECT package_name,
           COUNT(*) AS frequency
    FROM   packages
    WHERE  package_name IS NOT NULL
      AND  package_name <> ''
    GROUP BY package_name
)
SELECT package_name AS "package_name",
       frequency     AS "frequency"
FROM   pkg_counts
ORDER  BY frequency DESC NULLS LAST, package_name
LIMIT  10;