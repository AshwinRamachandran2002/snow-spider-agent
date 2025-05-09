WITH code_files AS (      -- only Python / R / notebook files
    SELECT "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") RLIKE '\\.(py|r|rmd|ipynb)$'
),

exploded AS (             -- one row per line of source
    SELECT VALUE::TEXT AS line
    FROM code_files,
         LATERAL FLATTEN( INPUT => SPLIT("content", '\n') )
),

/* -------- extract imported / loaded module names ---------------------- */
py_import AS (            --  lines like:  import x
    SELECT REGEXP_SUBSTR(line,
                         '\\bimport\\s+([A-Za-z0-9_\\.]+)',
                         1, 1, 'i', 1) AS lib
    FROM exploded
    WHERE REGEXP_LIKE(line, '\\bimport\\s+[A-Za-z0-9_\\.]+', 'i')
),
py_from AS (              --  lines like:  from x import y
    SELECT REGEXP_SUBSTR(line,
                         '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import',
                         1, 1, 'i', 1) AS lib
    FROM exploded
    WHERE REGEXP_LIKE(line, '\\bfrom\\s+[A-Za-z0-9_\\.]+\\s+import', 'i')
),
r_library AS (            --  lines like:  library(x)
    SELECT REGEXP_SUBSTR(line,
                         '\\blibrary\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                         1, 1, 'i', 1) AS lib
    FROM exploded
    WHERE REGEXP_LIKE(line, '\\blibrary\\s*\\(', 'i')
),
r_require AS (            --  lines like:  require(x)
    SELECT REGEXP_SUBSTR(line,
                         '\\brequire\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                         1, 1, 'i', 1) AS lib
    FROM exploded
    WHERE REGEXP_LIKE(line, '\\brequire\\s*\\(', 'i')
),

/* -------- combine every found library name ---------------------------- */
all_libs AS (
    SELECT LOWER(lib) AS lib FROM py_import  WHERE lib IS NOT NULL
    UNION ALL
    SELECT LOWER(lib)       FROM py_from    WHERE lib IS NOT NULL
    UNION ALL
    SELECT LOWER(lib)       FROM r_library  WHERE lib IS NOT NULL
    UNION ALL
    SELECT LOWER(lib)       FROM r_require  WHERE lib IS NOT NULL
),

/* -------- count frequency of each library ----------------------------- */
freq AS (
    SELECT lib, COUNT(*) AS cnt
    FROM all_libs
    GROUP BY lib
),

/* -------- rank libraries by frequency --------------------------------- */
ranked AS (
    SELECT
        lib,
        cnt,
        ROW_NUMBER() OVER (ORDER BY cnt DESC, lib) AS rn
    FROM freq
)

/* -------- return the 2nd most frequent (or 1st if only one exists) ---- */
SELECT COALESCE(
           MAX(CASE WHEN rn = 2 THEN lib END),
           MAX(CASE WHEN rn = 1 THEN lib END)
       ) AS "SECOND_MOST_IMPORTED_LIBRARY"
FROM ranked;