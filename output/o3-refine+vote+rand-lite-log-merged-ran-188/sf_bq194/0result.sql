WITH all_imports AS (

    /* ---------- Python sources ---------- */
    SELECT LOWER(
             REGEXP_SUBSTR(st.value::STRING,
                           '(from|import)\\s+([A-Za-z0-9_\\.]+)',
                           1, 1, 'i', 2)
           ) AS mod
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  sc,
           LATERAL SPLIT_TO_TABLE(sc."content", '\n') st
    WHERE  sc."sample_path" ILIKE '%.py'
      AND  st.value ILIKE '%import %'

    UNION ALL

    /* ---------- R sources (.r / .R / .rmd / .Rmd) ---------- */
    SELECT LOWER(
             REGEXP_SUBSTR(st.value::STRING,
                           '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9_.]+)',
                           1, 1, 'i', 2)
           ) AS mod
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  sc,
           LATERAL SPLIT_TO_TABLE(sc."content", '\n') st
    WHERE (LOWER(sc."sample_path") LIKE '%.r'   OR
           LOWER(sc."sample_path") LIKE '%.rmd')
      AND  (st.value ILIKE '%library(%' OR st.value ILIKE '%require(%')

    UNION ALL

    /* ---------- IPython notebooks ---------- */
    SELECT LOWER(
             REGEXP_SUBSTR(st.value::STRING,
                           '(from|import)\\s+([A-Za-z0-9_\\.]+)',
                           1, 1, 'i', 2)
           ) AS mod
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  sc,
           LATERAL SPLIT_TO_TABLE(sc."content", '\n') st
    WHERE  sc."sample_path" ILIKE '%.ipynb'
      AND  st.value ILIKE '%import %'
),

module_counts AS (
    SELECT mod,
           COUNT(*) AS total_imports
    FROM   all_imports
    WHERE  mod IS NOT NULL
    GROUP  BY mod
)

SELECT mod           AS "module_name",
       total_imports AS "total_occurrences"
FROM   module_counts
QUALIFY ROW_NUMBER() OVER (ORDER BY total_imports DESC NULLS LAST) = 2;