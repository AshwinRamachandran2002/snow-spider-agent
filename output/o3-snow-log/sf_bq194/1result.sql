WITH
/* -------- Python source files (.py) -------- */
py_modules AS (
    /* pattern:  import <module> */
    SELECT REGEXP_SUBSTR(line,'import\\s+([A-Za-z0-9_\\.]+)',1,1,'e',1) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content",'\n')) f,
         LATERAL ( SELECT f.value::STRING AS line )
    WHERE c."sample_path" ILIKE '%.py'
      AND REGEXP_LIKE(line,'^\\s*import\\s+[A-Za-z0-9_\\.]+')

    UNION ALL

    /* pattern:  from <module> import ... */
    SELECT REGEXP_SUBSTR(line,'from\\s+([A-Za-z0-9_\\.]+)',1,1,'e',1) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content",'\n')) f,
         LATERAL ( SELECT f.value::STRING AS line )
    WHERE c."sample_path" ILIKE '%.py'
      AND line ILIKE '%from %import %'
),

/* -------- IPython notebooks (.ipynb) -------- */
ipynb_modules AS (
    /* import <module> */
    SELECT REGEXP_SUBSTR(line,'import\\s+([A-Za-z0-9_\\.]+)',1,1,'e',1) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content",'\n')) f,
         LATERAL ( SELECT f.value::STRING AS line )
    WHERE c."sample_path" ILIKE '%.ipynb'
      AND REGEXP_LIKE(line,'import\\s+[A-Za-z0-9_\\.]+')

    UNION ALL

    /* from <module> import ... */
    SELECT REGEXP_SUBSTR(line,'from\\s+([A-Za-z0-9_\\.]+)',1,1,'e',1) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content",'\n')) f,
         LATERAL ( SELECT f.value::STRING AS line )
    WHERE c."sample_path" ILIKE '%.ipynb'
      AND line ILIKE '%from %import %'
),

/* -------- R sources (.r, .R, .rmd, .Rmd) -------- */
r_modules AS (
    /* library(<pkg>) */
    SELECT REGEXP_SUBSTR(line,'library\\(([^)]+)\\)',1,1,'e',1) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content",'\n')) f,
         LATERAL ( SELECT f.value::STRING AS line )
    WHERE LOWER(c."sample_path") LIKE '%.r%'
      AND REGEXP_LIKE(line,'library\\([^)]+\\)')

    UNION ALL

    /* require(<pkg>) */
    SELECT REGEXP_SUBSTR(line,'require\\(([^)]+)\\)',1,1,'e',1) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content",'\n')) f,
         LATERAL ( SELECT f.value::STRING AS line )
    WHERE LOWER(c."sample_path") LIKE '%.r%'
      AND REGEXP_LIKE(line,'require\\([^)]+\\)')
),

/* -------- Combine & count -------- */
all_modules AS (
    SELECT module FROM py_modules
    UNION ALL
    SELECT module FROM ipynb_modules
    UNION ALL
    SELECT module FROM r_modules
),
module_counts AS (
    SELECT module,
           COUNT(*) AS cnt
    FROM   all_modules
    WHERE  module IS NOT NULL
    GROUP  BY module
)

/* -------- second most frequent module/library -------- */
SELECT module,
       cnt
FROM   module_counts
QUALIFY ROW_NUMBER() OVER (ORDER BY cnt DESC NULLS LAST) = 2;