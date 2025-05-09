WITH files_with_contents AS (
    SELECT
        f."path",
        c."content"
    FROM
        GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES  AS f
        JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
              ON f."id" = c."id"
    WHERE
        c."content" IS NOT NULL
        AND LENGTH(TRIM(c."content")) > 0          -- keep only non‑empty contents
),
classified AS (
    SELECT
        CASE
            WHEN LOWER(REGEXP_SUBSTR("path", '[^/]+$')) IN ('dockerfile')
                 OR LOWER("path") ILIKE '%/dockerfile' OR LOWER("path") ILIKE '%.dockerfile'        THEN 'Dockerfile'
            WHEN LOWER("path") ILIKE '%.asm'     OR LOWER("path") ILIKE '%.nasm'                    THEN 'Assembly'
            WHEN LOWER("path") ILIKE '%.c++'     OR LOWER("path") ILIKE '%.cpp'
                 OR LOWER("path") ILIKE '%.h++'  OR LOWER("path") ILIKE '%.hpp'                     THEN 'C++'
            WHEN LOWER("path") ILIKE '%.cs'                                                               THEN 'C#'
            WHEN LOWER("path") ILIKE '%.c'       OR LOWER("path") ILIKE '%.h'                        THEN 'C'
            WHEN LOWER("path") ILIKE '%.css'                                                             THEN 'CSS'
            WHEN LOWER("path") ILIKE '%.clj'                                                             THEN 'Clojure'
            WHEN LOWER("path") ILIKE '%.lisp'                                                            THEN 'Common Lisp'
            WHEN LOWER("path") ILIKE '%.d'                                                               THEN 'D'
            WHEN LOWER("path") ILIKE '%.dart'                                                            THEN 'Dart'
            WHEN LOWER("path") ILIKE '%.ex'      OR LOWER("path") ILIKE '%.exs'                       THEN 'Elixir'
            WHEN LOWER("path") ILIKE '%.erl'                                                             THEN 'Erlang'
            WHEN LOWER("path") ILIKE '%.go'                                                              THEN 'Go'
            WHEN LOWER("path") ILIKE '%.groovy'                                                          THEN 'Groovy'
            WHEN LOWER("path") ILIKE '%.html'    OR LOWER("path") ILIKE '%.htm'                       THEN 'HTML'
            WHEN LOWER("path") ILIKE '%.hs'                                                              THEN 'Haskell'
            WHEN LOWER("path") ILIKE '%.hx'                                                              THEN 'Haxe'
            WHEN LOWER("path") ILIKE '%.json'                                                            THEN 'JSON'
            WHEN LOWER("path") ILIKE '%.java'                                                            THEN 'Java'
            WHEN LOWER("path") ILIKE '%.js'      OR LOWER("path") ILIKE '%.cjs'                       THEN 'JavaScript'
            WHEN LOWER("path") ILIKE '%.jl'                                                              THEN 'Julia'
            WHEN LOWER("path") ILIKE '%.kt'      OR LOWER("path") ILIKE '%.ktm'
                 OR LOWER("path") ILIKE '%.kts'                                                         THEN 'Kotlin'
            WHEN LOWER("path") ILIKE '%.lua'                                                             THEN 'Lua'
            WHEN LOWER("path") ILIKE '%.matlab'  OR LOWER("path") ILIKE '%.m'                         THEN 'MATLAB'
            WHEN LOWER("path") ILIKE '%.md'      OR LOWER("path") ILIKE '%.markdown'
                 OR LOWER("path") ILIKE '%.mdown'                                                       THEN 'Markdown'
            WHEN LOWER("path") ILIKE '%.php'                                                             THEN 'PHP'
            WHEN LOWER("path") ILIKE '%.ps1'     OR LOWER("path") ILIKE '%.psd1'
                 OR LOWER("path") ILIKE '%.psm1'                                                        THEN 'PowerShell'
            WHEN LOWER("path") ILIKE '%.py'                                                              THEN 'Python'
            WHEN LOWER("path") ILIKE '%.r'                                                               THEN 'R'
            WHEN LOWER("path") ILIKE '%.rb'                                                              THEN 'Ruby'
            WHEN LOWER("path") ILIKE '%.rs'                                                              THEN 'Rust'
            WHEN LOWER("path") ILIKE '%.scss'                                                            THEN 'SCSS'
            WHEN LOWER("path") ILIKE '%.sql'                                                             THEN 'SQL'
            WHEN LOWER("path") ILIKE '%.sass'                                                            THEN 'Sass'
            WHEN LOWER("path") ILIKE '%.scala'                                                           THEN 'Scala'
            WHEN LOWER("path") ILIKE '%.sh'      OR LOWER("path") ILIKE '%.bash'                      THEN 'Shell'
            WHEN LOWER("path") ILIKE '%.swift'                                                           THEN 'Swift'
            WHEN LOWER("path") ILIKE '%.ts'                                                              THEN 'TypeScript'
            WHEN LOWER("path") ILIKE '%.vue'                                                             THEN 'Vue'
            WHEN LOWER("path") ILIKE '%.xml'                                                             THEN 'XML'
            WHEN LOWER("path") ILIKE '%.yml'     OR LOWER("path") ILIKE '%.yaml'                      THEN 'YAML'
        END AS "language"
    FROM files_with_contents
)
SELECT
    "language",
    COUNT(*) AS "file_count"
FROM
    classified
WHERE
    "language" IS NOT NULL
GROUP BY
    "language"
ORDER BY
    "file_count" DESC NULLS LAST,
    "language"
LIMIT 10;