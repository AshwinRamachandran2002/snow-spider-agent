WITH readme_lines AS (   -- every non-empty, non-comment line from README.md files
    SELECT
        TRIM(s.value)                      AS line_text,
        c."sample_repo_name"               AS repo_name
    FROM  GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS"  c,
          LATERAL SPLIT_TO_TABLE(c."content", '\n') s
    WHERE LOWER(c."sample_path") LIKE '%readme.md'
      AND TRIM(s.value) <> ''              -- drop blank lines
      AND NOT TRIM(s.value) ILIKE '#%'     -- drop “# …”
      AND NOT TRIM(s.value) ILIKE '//%'    -- drop “// …”
),

/* how often each unique line occurs (may repeat in same repo/file) */
line_freq AS (
    SELECT line_text,
           COUNT(*)        AS frequency
    FROM   readme_lines
    GROUP  BY line_text
),

/* gather distinct language lists for repos that contain each line */
line_lang AS (
    SELECT
        rl.line_text,
        ARRAY_TO_STRING(
            ARRAY_SORT(ARRAY_AGG(DISTINCT l."language"::STRING)),
            ','
        )            AS languages
    FROM   readme_lines                       rl
    JOIN   GITHUB_REPOS.GITHUB_REPOS."LANGUAGES"  l
           ON rl.repo_name = l."repo_name"
    GROUP  BY rl.line_text
)

SELECT
    lf.line_text      AS useful_line,
    lf.frequency,
    ll.languages
FROM   line_freq  lf
JOIN   line_lang  ll
       ON lf.line_text = ll.line_text
ORDER  BY lf.frequency DESC NULLS LAST;