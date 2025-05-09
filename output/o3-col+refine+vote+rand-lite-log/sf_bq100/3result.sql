/* top-10 most common packages referenced in grouped “import (…)” blocks */
WITH candidate_files AS (
    /* 1. only take files that contain a Go-style grouped import statement */
    SELECT "id",
           "content"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "content" ILIKE '%import (%'
),
import_lines AS (
    /* 2. break each file into individual lines and pull the text inside
          the first pair of double quotes (if any)                 */
    SELECT REGEXP_SUBSTR(line.value::STRING,
                         '"([^"]+)"',      -- capture what’s inside quotes
                         1, 1, 'e', 1) AS pkg
    FROM   candidate_files,
           LATERAL FLATTEN(INPUT => SPLIT("content", '\n')) AS line
    WHERE  REGEXP_SUBSTR(line.value::STRING,
                         '"([^"]+)"', 1, 1, 'e', 1) IS NOT NULL
)
SELECT  pkg      AS "package",
        COUNT(*) AS "frequency"
FROM    import_lines
GROUP BY pkg
ORDER BY "frequency" DESC NULLS LAST
LIMIT 10;