/* Find the 2-nd most frequently imported / loaded library or module
   across Python (*.py), R (*.r / *.rmd) and notebook (*.ipynb) files */
WITH extracted AS (

    /* ---------- Python & notebooks :  “import <module>” ---------- */
    SELECT
        REGEXP_SUBSTR(line.value,
                      'import\\s+([A-Za-z0-9_\\.]+)',
                      1, 1, 'ie', 1)   AS "module"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
          LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
    WHERE REGEXP_LIKE(LOWER(sc."sample_path"), '.*\\.(py|ipynb)$')
      AND REGEXP_LIKE(line.value,
                      '^\\s*import\\s+[A-Za-z0-9_\\.]+', 'i')

    UNION ALL

    /* ---------- Python & notebooks :  “from <module> import …” --- */
    SELECT
        REGEXP_SUBSTR(line.value,
                      'from\\s+([A-Za-z0-9_\\.]+)\\s+import',
                      1, 1, 'ie', 1)   AS "module"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
          LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
    WHERE REGEXP_LIKE(LOWER(sc."sample_path"), '.*\\.(py|ipynb)$')
      AND REGEXP_LIKE(line.value,
                      '^\\s*from\\s+[A-Za-z0-9_\\.]+\\s+import', 'i')

    UNION ALL

    /* ---------- R files :  library(x) / require(x) --------------- */
    SELECT
        REGEXP_SUBSTR(line.value,
                      '(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                      1, 1, 'ie', 2)   AS "module"          -- return 2-nd capture group
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
          LATERAL SPLIT_TO_TABLE(sc."content", '\n') line
    WHERE REGEXP_LIKE(LOWER(sc."sample_path"), '.*\\.(r|rmd)$')
      AND REGEXP_LIKE(line.value,
                      '\\b(library|require)\\s*\\(', 'i')
),

ranked AS (
    SELECT
        "module",
        COUNT(*)                                   AS "appearances",
        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS "rnk"
    FROM extracted
    WHERE "module" IS NOT NULL
    GROUP BY "module"
)

SELECT
    "module"      AS "second_most_imported_module",
    "appearances"
FROM ranked
WHERE "rnk" = 2;