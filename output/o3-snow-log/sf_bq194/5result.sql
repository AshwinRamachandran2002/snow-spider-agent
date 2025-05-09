/* ---------- 2-nd most frequently imported / loaded module (Python, R, Rmd, ipynb) ---------- */
WITH file_contents AS (   /* files for which we have the text */
    SELECT
        sf."path",
        LOWER(sf."path") AS lower_path,
        sc."content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    sf
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
          ON sf."id" = sc."id"
    WHERE LOWER(sf."path") LIKE '%.py'
       OR LOWER(sf."path") LIKE '%.r'
       OR LOWER(sf."path") LIKE '%.rmd'
       OR LOWER(sf."path") LIKE '%.ipynb'
),
lines AS (                 /* split each file into lines */
    SELECT
        fc.lower_path,
        TRIM(value::string) AS line
    FROM file_contents fc,
         LATERAL SPLIT_TO_TABLE(fc."content", '\n')
),

/* ---- extract import / load statements ------------------------------ */
py_imports AS (            /* Python: capture group 2 = module name   */
    SELECT LOWER(
             REGEXP_SUBSTR(
                 line,
                 '^\\s*(from|import)\\s+([A-Za-z0-9_\\.]+)',
                 1, 1, 'e', 2
             )
           ) AS lib
    FROM lines
    WHERE lower_path LIKE '%.py'
      AND REGEXP_LIKE(line, '^\\s*(from|import)\\s+[A-Za-z0-9_]')
),
r_imports AS (             /* R / Rmd: capture group 2 = package name */
    SELECT LOWER(
             REGEXP_SUBSTR(
                 line,
                 '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                 1, 1, 'e', 2
             )
           ) AS lib
    FROM lines
    WHERE (lower_path LIKE '%.r' OR lower_path LIKE '%.rmd')
      AND REGEXP_LIKE(line, '\\b(library|require)\\s*\\(')
),
nb_imports AS (            /* Jupyter notebooks (assumed Python)      */
    SELECT LOWER(
             REGEXP_SUBSTR(
                 line,
                 'import\\s+([A-Za-z0-9_\\.]+)',
                 1, 1, 'e', 1
             )
           ) AS lib
    FROM lines
    WHERE lower_path LIKE '%.ipynb'
      AND REGEXP_LIKE(line, 'import\\s+[A-Za-z0-9_]')
),

all_imports AS (           /* union everything together               */
      SELECT lib FROM py_imports
      UNION ALL
      SELECT lib FROM r_imports
      UNION ALL
      SELECT lib FROM nb_imports
),
lib_counts AS (            /* count occurrences                       */
    SELECT lib, COUNT(*) AS freq
    FROM all_imports
    WHERE lib IS NOT NULL
    GROUP BY lib
),
ordered AS (               /* rank by frequency                       */
    SELECT
        lib,
        freq,
        ROW_NUMBER() OVER (ORDER BY freq DESC NULLS LAST) AS rn
    FROM lib_counts
)

/* ---- return exactly one row: the 2-nd most frequent module --------- */
SELECT
    COALESCE(MAX(CASE WHEN rn = 2 THEN lib  END), 'N/A') AS "second_most_frequent_library",
    COALESCE(MAX(CASE WHEN rn = 2 THEN freq END), 0)     AS "import_count"
FROM ordered;