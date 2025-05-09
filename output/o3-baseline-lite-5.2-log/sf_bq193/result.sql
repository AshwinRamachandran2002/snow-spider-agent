WITH readme_files AS (
    /* every README.md together with its repository’s language information */
    SELECT
        f."repo_name",
        f."id",
        c."content",
        l."language"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c  ON c."id" = f."id"
    LEFT JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES   l  ON l."repo_name" = f."repo_name"
    WHERE LOWER(f."path") LIKE '%readme.md'          -- README files only
),
lines AS (
    /* split each README into individual, trimmed lines
       – keep non‑empty lines that do NOT start with “#” or “//”                */
    SELECT
        rf."repo_name",
        TRIM(fl.value::string) AS line
    FROM readme_files rf,
         LATERAL FLATTEN( INPUT => SPLIT(rf."content", '\n') ) fl
    WHERE TRIM(fl.value::string) <> ''
      AND NOT REGEXP_LIKE(TRIM(fl.value::string), '^(#|//)')
),
line_repo AS (
    /* distinct (line, repo) pairs */
    SELECT DISTINCT
        line,
        "repo_name"
    FROM lines
),
repo_lang AS (
    /* explode the language variant for every repository into one row per language */
    SELECT
        rl."repo_name",
        fl.value::string AS lang
    FROM (
        SELECT DISTINCT "repo_name", "language"
        FROM readme_files
    ) rl
    LEFT JOIN LATERAL FLATTEN(
        INPUT => CASE
                   WHEN IS_OBJECT(rl."language") THEN OBJECT_KEYS(rl."language")
                   WHEN IS_ARRAY (rl."language") THEN rl."language"
                   ELSE ARRAY_CONSTRUCT(rl."language")
                 END
    ) fl
),
line_langs AS (
    /* combine each line with every language used in the repos that contain it */
    SELECT
        lr.line,
        rl.lang
    FROM line_repo lr
    JOIN repo_lang rl
      ON lr."repo_name" = rl."repo_name"
    WHERE rl.lang IS NOT NULL
)
SELECT
    lr.line                                                   AS "LINE",
    COUNT(DISTINCT lr."repo_name")                            AS "FREQUENCY",
    ARRAY_TO_STRING( ARRAY_SORT( ARRAY_AGG(DISTINCT ll.lang) )
                    , ',' )                                   AS "LANGUAGES"
FROM line_repo lr
LEFT JOIN line_langs ll
       ON lr.line = ll.line
GROUP BY lr.line
ORDER BY "FREQUENCY" DESC NULLS LAST,
         "LINE";