WITH
/* --------- extract python "import <module>" --------------------------- */
py_import AS (
    SELECT
        LOWER(
            REGEXP_SUBSTR(line.value,
                          'import[[:space:]]+([A-Za-z0-9_.]+)',
                          1, 1, 'i', 1)
        )                             AS module
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"     sf
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  sc
          ON sc."id" = sf."id"
         ,LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) line
    WHERE sf."path" ILIKE '%.py'
      AND line.value ILIKE 'import %'
),
/* --------- extract python "from <package> import" --------------------- */
py_from AS (
    SELECT
        LOWER(
            REGEXP_SUBSTR(line.value,
                          'from[[:space:]]+([A-Za-z0-9_.]+)[[:space:]]+import',
                          1, 1, 'i', 1)
        )                             AS module
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"     sf
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  sc
          ON sc."id" = sf."id"
         ,LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) line
    WHERE sf."path" ILIKE '%.py'
      AND line.value ILIKE 'from %import%'
),
/* --------- extract R  library(<pkg>) ---------------------------------- */
r_library AS (
    SELECT
        LOWER(
            REGEXP_SUBSTR(line.value,
                          'library\\(([A-Za-z0-9_.]+)\\)',
                          1, 1, 'i', 1)
        )                             AS module
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"     sf
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  sc
          ON sc."id" = sf."id"
         ,LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) line
    WHERE sf."path" ILIKE '%.r'
      AND line.value ILIKE '%library(%'
),
/* --------- union all results with language tag ------------------------ */
all_modules AS (
    SELECT 'python' AS language, module FROM py_import WHERE module IS NOT NULL
    UNION ALL
    SELECT 'python' AS language, module FROM py_from   WHERE module IS NOT NULL
    UNION ALL
    SELECT 'r'      AS language, module FROM r_library WHERE module IS NOT NULL
)
/* --------- final aggregation & sorting -------------------------------- */
SELECT
    language,
    module,
    COUNT(*) AS occurrences
FROM all_modules
GROUP BY language, module
ORDER BY
    language,
    occurrences DESC NULLS LAST;