WITH lines AS (   -- read every file, keep lines that could contain Python/R imports
    SELECT  f."path",
            REGEXP_REPLACE(ln.value, '\\r', '') AS line
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
    JOIN    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
           ON c."id" = f."id",
            LATERAL SPLIT_TO_TABLE(c."content", '\n') ln
    WHERE   REGEXP_LIKE( LOWER(f."path"), '\\.(py|ipynb|r|rmd)$')
            OR REGEXP_LIKE( ln.value ,
                '^\\s*import\\s+[A-Za-z0-9_]+'
              || '|^\\s*from\\s+[A-Za-z0-9_]+\\s+import'
              || '|\\blibrary\\s*\\('
              || '|\\brequire\\s*\\(' )
),
imports AS (      -- pull out the module / library names
    /* Python:  import module */
    SELECT LOWER( REGEXP_SUBSTR(line,
                                '^\\s*import\\s+([A-Za-z0-9_]+)',
                                1, 1, 'e', 1) ) AS lib
    FROM   lines
    WHERE  REGEXP_LIKE(line, '^\\s*import\\s+[A-Za-z0-9_]+')

    UNION ALL
    /* Python:  from module import ... */
    SELECT LOWER( REGEXP_SUBSTR(line,
                                '^\\s*from\\s+([A-Za-z0-9_]+)',
                                1, 1, 'e', 1) )
    FROM   lines
    WHERE  REGEXP_LIKE(line, '^\\s*from\\s+[A-Za-z0-9_]+\\s+import')

    UNION ALL
    /* R:  library(module) */
    SELECT LOWER( REGEXP_SUBSTR(line,
                                '\\blibrary\\s*\\(\\s*([A-Za-z0-9_.]+)',
                                1, 1, 'e', 1) )
    FROM   lines
    WHERE  REGEXP_LIKE(line, '\\blibrary\\s*\\(')

    UNION ALL
    /* R:  require(module) */
    SELECT LOWER( REGEXP_SUBSTR(line,
                                '\\brequire\\s*\\(\\s*([A-Za-z0-9_.]+)',
                                1, 1, 'e', 1) )
    FROM   lines
    WHERE  REGEXP_LIKE(line, '\\brequire\\s*\\(')
),
lib_counts AS (   -- count each library appearance
    SELECT lib,
           COUNT(*) AS import_count
    FROM   imports
    WHERE  lib IS NOT NULL AND lib <> ''
    GROUP  BY lib
)
SELECT lib
FROM   lib_counts
ORDER  BY import_count DESC NULLS LAST, lib      -- rank by frequency
LIMIT 1 OFFSET 1;   -- pick the 2nd most frequently imported/loaded library