WITH joined AS (
    SELECT
        c."sample_path" AS "path"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES   AS f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
          ON f."id" = c."id"
    WHERE c."binary" = FALSE
      AND c."content" IS NOT NULL
)
SELECT
    "language",
    COUNT(*) AS "file_count"
FROM (
    SELECT
        CASE
            /* special file-name without dot */
            WHEN LOWER(REGEXP_REPLACE("path", '^.*\/', '')) = 'dockerfile'
                 OR LOWER(SPLIT_PART("path", '.', -1)) = 'dockerfile'           THEN 'Dockerfile'

            WHEN LOWER(SPLIT_PART("path", '.', -1)) IN ('asm','nasm')           THEN 'Assembly'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) IN ('c','h')                THEN 'C'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) IN ('c++','cpp','h++','hpp')THEN 'C++'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'cs'                      THEN 'C#'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'css'                     THEN 'CSS'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) IN ('html','htm')           THEN 'HTML'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'java'                    THEN 'Java'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) IN ('js','cjs')             THEN 'JavaScript'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'json'                    THEN 'JSON'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'kt'                      THEN 'Kotlin'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'md'                      THEN 'Markdown'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) IN ('m','matlab')           THEN 'MATLAB'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'php'                     THEN 'PHP'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'py'                      THEN 'Python'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'rb'                      THEN 'Ruby'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'rs'                      THEN 'Rust'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) IN ('sh','bash')            THEN 'Shell'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) = 'ts'                      THEN 'TypeScript'
            WHEN LOWER(SPLIT_PART("path", '.', -1)) IN ('yml','yaml')           THEN 'YAML'
            ELSE 'Other'
        END AS "language"
    FROM joined
)
GROUP BY "language"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 10;