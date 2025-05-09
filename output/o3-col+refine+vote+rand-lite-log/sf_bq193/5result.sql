WITH readme_lines AS (
    /* 1. Extract distinct, non-empty, non-comment lines from README files */
    SELECT DISTINCT
           f."repo_name",
           TRIM(t.value)::STRING AS "line"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
           ON f."id" = c."id",
           LATERAL SPLIT_TO_TABLE(c."content", '\n') t
    WHERE  f."path" ILIKE '%README.md%'
      AND  TRIM(t.value) <> ''
      AND  TRIM(t.value) NOT LIKE '#%'      -- skip markdown comments/headings
      AND  TRIM(t.value) NOT LIKE '//%'     -- skip code-style comments
),
repo_langs AS (
    /* 2. Flatten languages array and keep only the language names */
    SELECT
           l."repo_name",
           f.value:"name"::STRING AS "language"
    FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
           LATERAL FLATTEN(input => l."language") f
),
line_repo_langs AS (
    /* 3. Associate each cleaned line with the languages of its repository */
    SELECT
           r."line",
           r."repo_name",
           pl."language"
    FROM   readme_lines r
    LEFT JOIN repo_langs pl
           ON r."repo_name" = pl."repo_name"
)
SELECT
       "line",
       COUNT(DISTINCT "repo_name")                                           AS "repo_count",
       ARRAY_TO_STRING(ARRAY_SORT(ARRAY_AGG(DISTINCT "language")), ',')      AS "languages"
FROM   line_repo_langs
GROUP  BY "line"
ORDER  BY "repo_count" DESC NULLS LAST;