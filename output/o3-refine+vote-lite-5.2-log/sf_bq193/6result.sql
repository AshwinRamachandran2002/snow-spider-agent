WITH "README_FILES" AS (
    SELECT
        "sample_repo_name"  AS "repo_name",
        "sample_path"       AS "path",
        "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%readme.md'
),
/* split every README into individual lines */
"README_LINES" AS (
    SELECT
        rf."repo_name",
        TRIM(f.value::STRING) AS "line"
    FROM "README_FILES" rf,
         LATERAL FLATTEN( INPUT => SPLIT(rf."content", '\n') ) f
    WHERE TRIM(f.value::STRING) <> ''                        -- non‑empty
      AND NOT TRIM(f.value::STRING) RLIKE '^(#|//)'          -- not a comment
),
/* explode the language information per repository */
"REPO_LANGS" AS (
    SELECT
        l."repo_name",
        fl.key::STRING AS "language"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN( INPUT => l."language" ) fl          -- works for VARIANT
),
/* associate every (repo,line) with the repo's languages */
"LINE_WITH_LANGS" AS (
    SELECT
        rl."line",
        rl."repo_name",
        rl."repo_name"      AS "repo_for_count",              -- keep for counting
        rl."repo_name"      AS "repo_for_lang_join"
    FROM "README_LINES" rl
),
"LINE_LANG_PAIRS" AS (
    SELECT
        lw."line",
        lw."repo_for_count"     AS "repo_name",
        rl2."language"
    FROM "LINE_WITH_LANGS" lw
    LEFT JOIN "REPO_LANGS" rl2
           ON lw."repo_for_lang_join" = rl2."repo_name"
),
/* aggregate: frequency (how many repositories) and language list */
"AGG" AS (
    SELECT
        "line",
        COUNT(DISTINCT "repo_name")                             AS "frequency",
        ARRAY_TO_STRING(
            ARRAY_SORT(ARRAY_AGG(DISTINCT "language")),
            ','
        )                                                       AS "languages"
    FROM "LINE_LANG_PAIRS"
    GROUP BY "line"
)
SELECT
    "line",
    "frequency",
    "languages"
FROM "AGG"
ORDER BY
    "frequency" DESC NULLS LAST,
    "line";