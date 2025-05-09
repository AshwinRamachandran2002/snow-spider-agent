WITH readme_lines AS (   -- every non‑empty, non‑comment line coming from a README.md file
    SELECT
        sf."repo_name",
        TRIM(f.value::string)                                                     AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES      sf
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS   sc   ON sc."id" = sf."id"
       ,LATERAL FLATTEN( INPUT => SPLIT(sc."content", '\n') )                     f
    WHERE sf."path" ILIKE '%README.md'                 -- README file only
      AND TRIM(f.value::string) <> ''                  -- non‑blank
      AND NOT REGEXP_LIKE( TRIM(f.value::string) , '^(#|//)' )   -- not a comment
),

/* turn the VARIANT column LANGUAGE into one row per repo‑language */
repo_language_arrays AS (
    SELECT
        "repo_name",
        CASE
            WHEN IS_OBJECT("language") THEN OBJECT_KEYS("language")
            WHEN IS_ARRAY ("language") THEN "language"
            ELSE ARRAY_CONSTRUCT()          -- no language info
        END                                                             AS lang_array
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
),
repo_languages AS (
    SELECT
        rla."repo_name",
        lf.value::string                                                AS language
    FROM repo_language_arrays  rla,
         LATERAL FLATTEN( INPUT => rla.lang_array )  lf
),

/* marry README lines with their repo languages (use UNKNOWN if none) */
line_repo_lang AS (
    SELECT
        rl.line,
        rl."repo_name",
        COALESCE(rlg.language, 'UNKNOWN')                               AS language
    FROM readme_lines  rl
    LEFT JOIN repo_languages  rlg
           ON rl."repo_name" = rlg."repo_name"
)

/* final aggregation */
SELECT
    line,
    COUNT(DISTINCT "repo_name")                                         AS frequency,
    ARRAY_TO_STRING(
        ARRAY_SORT(
            ARRAY_DISTINCT(
                ARRAY_AGG(DISTINCT language)
            )
        )
    , ',')                                                              AS languages
FROM line_repo_lang
GROUP BY line
ORDER BY frequency DESC NULLS LAST, line;