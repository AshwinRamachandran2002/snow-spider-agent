WITH readme_lines AS (
    /* 1. All non-empty, non-comment lines from README.md files */
    SELECT
        f."repo_name",
        TRIM(line.value::STRING)                             AS line_trimmed
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
         ON c."id" = f."id"
        ,LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n'))  line
    WHERE f."path" ILIKE '%README.md'
      AND TRIM(line.value::STRING) <> ''
      AND TRIM(line.value::STRING) NOT ILIKE '#%'      -- skip Markdown headers
      AND TRIM(line.value::STRING) NOT ILIKE '//%'     -- skip code comments
), repo_languages AS (
    /* 2. One row per repository-language pair */
    SELECT
        l."repo_name",
        lang.value:"name"::STRING                        AS language_name
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES  l,
         LATERAL FLATTEN(INPUT => l."language")  lang
    WHERE lang.value:"name" IS NOT NULL
), line_repo_lang AS (
    /* 3. Combine README lines with languages of their repositories */
    SELECT
        r.line_trimmed,
        r."repo_name",
        rl.language_name
    FROM readme_lines r
    LEFT JOIN repo_languages rl
           ON rl."repo_name" = r."repo_name"
)
SELECT
    line_trimmed                                   AS "unique_line",
    COUNT(DISTINCT "repo_name")                    AS "freq",
    ARRAY_TO_STRING(
        ARRAY_SORT(ARRAY_AGG(DISTINCT language_name))
    , ',')                                         AS "languages"
FROM line_repo_lang
GROUP BY line_trimmed
ORDER BY "freq" DESC NULLS LAST;