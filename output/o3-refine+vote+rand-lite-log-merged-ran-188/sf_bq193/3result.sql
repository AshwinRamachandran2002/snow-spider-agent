WITH readme_lines AS (   -- extract every useful line from README.md files
    SELECT
        sf."repo_name",
        TRIM(ln.value::STRING)      AS "readme_line"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     sf
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  sc
           ON sc."id" = sf."id",
           LATERAL SPLIT_TO_TABLE(sc."content", '\n') ln
    WHERE  sf."path" ILIKE '%README.md'                       -- only README files
      AND  TRIM(ln.value::STRING) <> ''                       -- non-empty lines
      AND  NOT REGEXP_LIKE(TRIM(ln.value::STRING), '^[[:space:]]*#')   -- skip “# …”
      AND  NOT REGEXP_LIKE(TRIM(ln.value::STRING), '^[[:space:]]*//')  -- skip “// …”
),
repo_languages AS (        -- turn each repo-language into its own row
    SELECT
        l."repo_name",
        lang.value:"name"::STRING AS "language"
    FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
           LATERAL FLATTEN(input => PARSE_JSON(l."language")) lang
)
SELECT
    rl."readme_line",
    COUNT(DISTINCT rl."repo_name")                                               AS "repo_count",
    LISTAGG(DISTINCT rl2."language", ',') WITHIN GROUP (ORDER BY rl2."language") AS "languages_used"
FROM   readme_lines  rl
LEFT   JOIN repo_languages rl2
       ON rl."repo_name" = rl2."repo_name"
GROUP  BY rl."readme_line"
ORDER  BY "repo_count" DESC NULLS LAST;