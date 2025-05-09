WITH chosen_files AS (  -- only files with extensions of interest
    SELECT  f."id"
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    WHERE   LOWER(f."path") LIKE '%.py'
        OR  LOWER(f."path") LIKE '%.r'
        OR  LOWER(f."path") LIKE '%.rmd'
        OR  LOWER(f."path") LIKE '%.ipynb'
),
all_lines AS (          -- split the file contents into individual lines
    SELECT  c."id",
            l.value      AS line
    FROM    chosen_files                 cf
    JOIN    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
              ON c."id" = cf."id",
            LATERAL SPLIT_TO_TABLE(c."content", '\n') l
),
extracted_libs AS (     -- try Python-style and R-style import patterns
    SELECT  LOWER(
              COALESCE(
                  REGEXP_SUBSTR(line,
                                 '\\b(import|from)\\s+([A-Za-z0-9_\\.]+)',
                                 1, 1, 'i', 2),                  -- group 2 = module name
                  REGEXP_SUBSTR(line,
                                 '(library|require)\\s*\\(\\s*["''`]?([A-Za-z0-9_\\.\\-]+)',
                                 1, 1, 'i', 2)                   -- group 2 = package name
              )
            ) AS lib
    FROM    all_lines
)
SELECT  lib AS "library_or_module"
FROM    (
        SELECT  lib,
                COUNT(*)                                  AS import_count,
                ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS rn
        FROM    extracted_libs
        WHERE   lib IS NOT NULL
        GROUP BY lib
) ranked
WHERE   rn = 2;