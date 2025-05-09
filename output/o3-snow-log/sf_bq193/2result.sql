WITH readme_lines AS (              -- 1. every relevant, cleaned README.md line
    SELECT
        f."repo_name",
        TRIM(line.value::STRING)                AS "clean_line"
    FROM  GITHUB_REPOS.GITHUB_REPOS."SAMPLE_FILES"     AS f
    JOIN  GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS"  AS c
          ON f."id" = c."id",
          LATERAL SPLIT_TO_TABLE(c."content", '\n')    AS line
    WHERE f."path" ILIKE '%README%.md%'               -- README-like files
      AND TRIM(line.value::STRING) <> ''              -- non-empty
      AND NOT TRIM(line.value::STRING) LIKE '#%'      -- skip markdown # comments
      AND NOT TRIM(line.value::STRING) LIKE '//%'     -- skip // comments
),                                                    -- 2. explode repo-language list
repo_langs AS (
    SELECT
        l."repo_name",
        fl.value:"name"::STRING  AS "language_name"
    FROM  GITHUB_REPOS.GITHUB_REPOS."LANGUAGES"        AS l,
          LATERAL FLATTEN(input => l."language")       AS fl
),                                                    -- 3. attach languages to lines
line_langs AS (
    SELECT
        rl."clean_line",
        rl."repo_name",
        rl2."language_name"
    FROM  readme_lines  AS rl
    LEFT JOIN repo_langs AS rl2
           ON rl."repo_name" = rl2."repo_name"
)
SELECT
    "clean_line",
    COUNT(*)                                             AS "line_occurrences",
    LISTAGG(DISTINCT "language_name", ', ')
      WITHIN GROUP (ORDER BY "language_name")            AS "languages"
FROM line_langs
GROUP BY "clean_line"
ORDER BY "line_occurrences" DESC NULLS LAST;