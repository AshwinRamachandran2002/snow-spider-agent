WITH candidates AS (
    SELECT 
        sf."id",
        sf."path",
        sc."content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES  sf
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
          ON sf."id" = sc."id"
    WHERE LOWER(sf."path") LIKE '%.py'
       OR LOWER(sf."path") LIKE '%.r'
), lines AS (
    SELECT 
        c."id",
        c."path",
        LOWER(f.value::string) AS line
    FROM candidates c,
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) f
), py_import AS (          --  lines like:  import numpy
    SELECT 
        'Python' AS language,
        TRIM(REGEXP_SUBSTR(line, '\\bimport\\s+([a-zA-Z0-9_\\.]+)', 1, 1, 'e', 1)) AS module
    FROM lines
    WHERE lines."path" ILIKE '%.py'
), py_from AS (            --  lines like:  from pandas.core import frame
    SELECT 
        'Python' AS language,
        TRIM(REGEXP_SUBSTR(line, '\\bfrom\\s+([a-zA-Z0-9_\\.]+)\\s+import', 1, 1, 'e', 1)) AS module
    FROM lines
    WHERE lines."path" ILIKE '%.py'
), r_lib AS (              --  lines like:  library(ggplot2)
    SELECT 
        'R' AS language,
        TRIM(REGEXP_SUBSTR(line, 'library\\s*\\(\\s*([a-zA-Z0-9_\\.]+)', 1, 1, 'e', 1)) AS module
    FROM lines
    WHERE lines."path" ILIKE '%.r'
), all_modules AS (
    SELECT * FROM py_import
    UNION ALL
    SELECT * FROM py_from
    UNION ALL
    SELECT * FROM r_lib
)
SELECT 
    language,
    module,
    COUNT(*) AS occurrences
FROM all_modules
WHERE module IS NOT NULL
GROUP BY language, module
ORDER BY 
    language,
    occurrences DESC NULLS LAST,
    module;