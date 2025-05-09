WITH python_imports AS (
    /* grab first “import <module> …” occurrences in Python files */
    SELECT REGEXP_SUBSTR("content",
                         '\\s*import\\s+([A-Za-z0-9_]+)',
                         1, 1, 'e', 1)   AS "module_name"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "sample_path" ILIKE '%.py'
      AND  REGEXP_SUBSTR("content",
                         '\\s*import\\s+([A-Za-z0-9_]+)',
                         1, 1, 'e', 1)   IS NOT NULL

    UNION ALL

    /* grab first “from <module> import …” occurrences in Python files */
    SELECT REGEXP_SUBSTR("content",
                         '\\s*from\\s+([A-Za-z0-9_]+)',
                         1, 1, 'e', 1)   AS "module_name"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "sample_path" ILIKE '%.py'
      AND  REGEXP_SUBSTR("content",
                         '\\s*from\\s+([A-Za-z0-9_]+)',
                         1, 1, 'e', 1)   IS NOT NULL
),

r_library_calls AS (
    /* grab first “library(<package>)” occurrences in R files */
    SELECT REGEXP_SUBSTR("content",
                         'library\\s*\\(\\s*([A-Za-z0-9._]+)',
                         1, 1, 'e', 1)   AS "module_name"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "sample_path" ILIKE '%.r'
      AND  REGEXP_SUBSTR("content",
                         'library\\s*\\(\\s*([A-Za-z0-9._]+)',
                         1, 1, 'e', 1)   IS NOT NULL
),

all_modules AS (
    SELECT "module_name" FROM python_imports
    UNION ALL
    SELECT "module_name" FROM r_library_calls
)

SELECT
  "module_name",
  COUNT(*) AS "module_usage_count"
FROM   all_modules
WHERE  "module_name" IS NOT NULL
GROUP  BY "module_name"
ORDER  BY "module_usage_count" DESC NULLS LAST
LIMIT 5;