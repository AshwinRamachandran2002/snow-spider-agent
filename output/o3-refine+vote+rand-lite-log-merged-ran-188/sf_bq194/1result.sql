WITH /* ---------------- Python (*.py) ---------------- */
python_lines AS (
    SELECT f.value::STRING AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL FLATTEN( INPUT => SPLIT(sc."content", '\n') ) f
    WHERE sc."sample_path" ILIKE '%.py'
),
py_imports AS (
    SELECT LOWER(
             REGEXP_SUBSTR(
                 line,
                 '^\\s*(from|import)\\s+([A-Za-z0-9_\\.]+)',
                 1, 1, 'e', 2           /* 2-nd capture group = lib name */
            )
           ) AS lib
    FROM python_lines
    WHERE line ILIKE 'import %' OR line ILIKE 'from % import %'
),

/* --------------- Jupyter notebooks (*.ipynb) -------- */
ipynb_lines AS (
    SELECT f.value::STRING AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL FLATTEN( INPUT => SPLIT(sc."content", '\n') ) f
    WHERE sc."sample_path" ILIKE '%.ipynb'
),
ipynb_imports AS (
    SELECT LOWER(
             REGEXP_SUBSTR(
                 line,
                 '^\\s*(from|import)\\s+([A-Za-z0-9_\\.]+)',
                 1, 1, 'e', 2
            )
           ) AS lib
    FROM ipynb_lines
    WHERE line ILIKE 'import %' OR line ILIKE 'from % import %'
),

/* ---------------- R / Rmd sources ------------------ */
r_lines AS (
    SELECT f.value::STRING AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc,
         LATERAL FLATTEN( INPUT => SPLIT(sc."content", '\n') ) f
    WHERE sc."sample_path" ILIKE '%.r'
       OR sc."sample_path" ILIKE '%.R'
       OR sc."sample_path" ILIKE '%.rmd'
       OR sc."sample_path" ILIKE '%.Rmd'
),
r_imports AS (
    SELECT LOWER(
             REGEXP_SUBSTR(
                 line,
                 '\\b(library|require)\\s*\\(\\s*[\"\']?([A-Za-z0-9_\\.]+)',
                 1, 1, 'e', 2
            )
           ) AS lib
    FROM r_lines
    WHERE line ILIKE '%library(%' OR line ILIKE '%require(%'
),

/* --------------- Combine & count ------------------- */
all_libs AS (
      SELECT lib FROM py_imports
  UNION ALL
      SELECT lib FROM ipynb_imports
  UNION ALL
      SELECT lib FROM r_imports
),
lib_counts AS (
    SELECT
        lib,
        COUNT(*) AS usage_count
    FROM all_libs
    WHERE lib IS NOT NULL
      AND lib NOT IN ('from','import','library','require')
    GROUP BY lib
)

/* --------------- 2nd most common ------------------- */
SELECT lib AS "library", usage_count
FROM (
    SELECT
        lib,
        usage_count,
        ROW_NUMBER() OVER (ORDER BY usage_count DESC NULLS LAST) AS rn
    FROM lib_counts
)
WHERE rn = 2;