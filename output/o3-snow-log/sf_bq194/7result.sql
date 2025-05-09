WITH module_refs AS (

    /* Python & notebooks : plain  `import <module>` */
    SELECT LOWER(REGEXP_SUBSTR("content",
                               'import\\s+([A-Za-z0-9_]+)',
                               1, 1, 'i', 1)) AS "name_or_pkg"
    FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE  ("sample_path" ILIKE '%.py' OR "sample_path" ILIKE '%.ipynb')
      AND  "content" ILIKE '%import %'

    UNION ALL

    /* Python & notebooks : `from <module> import ...` */
    SELECT LOWER(REGEXP_SUBSTR("content",
                               'from\\s+([A-Za-z0-9_]+)\\s+import',
                               1, 1, 'i', 1))
    FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE  ("sample_path" ILIKE '%.py' OR "sample_path" ILIKE '%.ipynb')
      AND  "content" ILIKE '%from %import%'

    UNION ALL

    /* R files : `library(package)` */
    SELECT LOWER(REGEXP_SUBSTR("content",
                               'library\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                               1, 1, 'i', 1))
    FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE  LOWER("sample_path") ILIKE '%.r%'
      AND  "content" ILIKE '%library(%'

    UNION ALL

    /* R files : `require(package)` */
    SELECT LOWER(REGEXP_SUBSTR("content",
                               'require\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                               1, 1, 'i', 1))
    FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
    WHERE  LOWER("sample_path") ILIKE '%.r%'
      AND  "content" ILIKE '%require(%'
),

freq AS (
    SELECT   "name_or_pkg",
             COUNT(*) AS "total_occurrences",
             ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS rn
    FROM     module_refs
    WHERE    "name_or_pkg" IS NOT NULL
    GROUP BY "name_or_pkg"
)

SELECT "name_or_pkg", "total_occurrences"
FROM   freq
WHERE  rn = 2;