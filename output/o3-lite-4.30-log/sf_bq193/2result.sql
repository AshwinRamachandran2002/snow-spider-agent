WITH valid_readme_lines AS (
    /* all non‑empty, non‑comment lines from non‑binary README.md files */
    SELECT DISTINCT
           f."repo_name",
           TRIM(l.value)::STRING AS "clean_line"
    FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"    f
    JOIN   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
           ON c."id" = f."id"
         , LATERAL SPLIT_TO_TABLE(c."content", '\n')       l
    WHERE  LOWER(f."path") LIKE '%readme.md'      -- only README.md files
      AND  c."binary" = FALSE                     -- skip binaries
      AND  TRIM(l.value) <> ''                    -- skip blank lines
      AND  NOT REGEXP_LIKE(TRIM(l.value), '^(#|//)')       -- skip comment lines
),
repo_languages AS (
    /* explode language arrays so each repo‑language pair is explicit */
    SELECT  lg."repo_name",
            COALESCE(lf.value:"name"::STRING, lf.value::STRING) AS "lang"
    FROM    "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES" lg,
            LATERAL FLATTEN(input => lg."language") lf
)
SELECT  v."clean_line"                                                  AS "line",
        COUNT(DISTINCT v."repo_name")                                   AS "occurrences",
        LISTAGG(DISTINCT rl."lang", ',') 
            WITHIN GROUP (ORDER BY rl."lang")                           AS "languages"
FROM    valid_readme_lines v
LEFT JOIN repo_languages rl
       ON rl."repo_name" = v."repo_name"
GROUP BY v."clean_line"
ORDER BY "occurrences" DESC NULLS LAST, "line";