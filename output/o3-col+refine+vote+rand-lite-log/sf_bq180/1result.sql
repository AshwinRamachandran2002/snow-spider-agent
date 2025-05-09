WITH line_table AS (               -- split Python & R files into lines
    SELECT
        LOWER(c."sample_path") AS sample_path,
        l.value                AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL SPLIT_TO_TABLE(c."content", '\n') l
    WHERE LOWER(c."sample_path") LIKE '%.py'
       OR LOWER(c."sample_path") LIKE '%.r'
),

/* --------------------- Python modules ---------------------------------- */
py_imports AS (                    -- lines with  “import <module>”
    SELECT REGEXP_SUBSTR(line,
                         '\\bimport\\s+([A-Za-z0-9_.]+)',
                         1, 1, 'e', 1)              AS mod
    FROM line_table
    WHERE sample_path LIKE '%.py'
      AND REGEXP_LIKE(line, '\\bimport\\s+[A-Za-z0-9_.]+', 'i')
),
py_froms AS (                      -- lines with “from <module> import”
    SELECT REGEXP_SUBSTR(line,
                         '\\bfrom\\s+([A-Za-z0-9_.]+)',
                         1, 1, 'e', 1)              AS mod
    FROM line_table
    WHERE sample_path LIKE '%.py'
      AND REGEXP_LIKE(line, '\\bfrom\\s+[A-Za-z0-9_.]+', 'i')
),
py_modules AS (
    SELECT LOWER(SPLIT_PART(mod, '.', 1)) AS module
    FROM (
        SELECT mod FROM py_imports
        UNION ALL
        SELECT mod FROM py_froms
    )
    WHERE mod IS NOT NULL AND mod <> ''
),

/* ----------------------- R modules ------------------------------------- */
r_modules AS (
    SELECT LOWER(
               REGEXP_SUBSTR(
                   line,
                   '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9_.]+)',
                   1, 1, 'e', 2)                    -- capture group 2 = package
           ) AS module
    FROM line_table
    WHERE sample_path LIKE '%.r'
      AND REGEXP_LIKE(line, '\\b(library|require)\\s*\\(', 'i')
      AND REGEXP_SUBSTR(line,
                         '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9_.]+)',
                         1, 1, 'e', 2) IS NOT NULL
),

/* ----------------------- All modules ----------------------------------- */
all_modules AS (
    SELECT module FROM py_modules
    UNION ALL
    SELECT module FROM r_modules
)

/* ----------------------- Aggregate & return ---------------------------- */
SELECT
    module,
    COUNT(*) AS usage_count
FROM all_modules
GROUP BY module
ORDER BY usage_count DESC NULLS LAST
LIMIT 5;