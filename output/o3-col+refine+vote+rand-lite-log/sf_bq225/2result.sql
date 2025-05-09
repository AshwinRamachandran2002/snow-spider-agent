WITH files_with_content AS (
    SELECT
        LOWER(SPLIT_PART(f."path", '.', -1)) AS "ext"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES  AS f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
      ON f."id" = c."id"
    WHERE c."content" IS NOT NULL
      AND TRIM(c."content") <> ''
)
SELECT
    "language",
    COUNT(*) AS "file_cnt"
FROM (
    SELECT
        CASE
            WHEN "ext" IN ('asm','nasm')                              THEN 'Assembly'
            WHEN "ext" IN ('c','h')                                   THEN 'C'
            WHEN "ext" =  'cs'                                        THEN 'C#'
            WHEN "ext" IN ('c++','cpp','cxx','cc','hpp','h++','hh')   THEN 'C++'
            WHEN "ext" =  'css'                                       THEN 'CSS'
            WHEN "ext" =  'clj'                                       THEN 'Clojure'
            WHEN "ext" =  'lisp'                                      THEN 'Common Lisp'
            WHEN "ext" =  'd'                                         THEN 'D'
            WHEN "ext" =  'dart'                                      THEN 'Dart'
            WHEN "ext" IN ('dockerfile','docker')                     THEN 'Dockerfile'
            WHEN "ext" IN ('ex','exs')                                THEN 'Elixir'
            WHEN "ext" =  'erl'                                       THEN 'Erlang'
            WHEN "ext" =  'go'                                        THEN 'Go'
            WHEN "ext" =  'groovy'                                    THEN 'Groovy'
            WHEN "ext" IN ('html','htm')                              THEN 'HTML'
            WHEN "ext" =  'hs'                                        THEN 'Haskell'
            WHEN "ext" =  'hx'                                        THEN 'Haxe'
            WHEN "ext" =  'json'                                      THEN 'JSON'
            WHEN "ext" =  'java'                                      THEN 'Java'
            WHEN "ext" IN ('js','cjs','mjs')                          THEN 'JavaScript'
            WHEN "ext" =  'jl'                                        THEN 'Julia'
            WHEN "ext" IN ('kt','ktm','kts')                          THEN 'Kotlin'
            WHEN "ext" =  'lua'                                       THEN 'Lua'
            WHEN "ext" IN ('matlab','m')                              THEN 'MATLAB'
            WHEN "ext" IN ('md','markdown','mdown')                   THEN 'Markdown'
            WHEN "ext" =  'php'                                       THEN 'PHP'
            WHEN "ext" IN ('ps1','psd1','psm1')                       THEN 'PowerShell'
            WHEN "ext" =  'py'                                        THEN 'Python'
            WHEN "ext" =  'r'                                         THEN 'R'
            WHEN "ext" =  'rb'                                        THEN 'Ruby'
            WHEN "ext" =  'rs'                                        THEN 'Rust'
            WHEN "ext" =  'scss'                                      THEN 'SCSS'
            WHEN "ext" =  'sql'                                       THEN 'SQL'
            WHEN "ext" =  'sass'                                      THEN 'Sass'
            WHEN "ext" =  'scala'                                     THEN 'Scala'
            WHEN "ext" IN ('sh','bash')                               THEN 'Shell'
            WHEN "ext" =  'swift'                                     THEN 'Swift'
            WHEN "ext" =  'ts'                                        THEN 'TypeScript'
            WHEN "ext" =  'vue'                                       THEN 'Vue'
            WHEN "ext" =  'xml'                                       THEN 'XML'
            WHEN "ext" IN ('yml','yaml')                              THEN 'YAML'
            ELSE 'Other'
        END AS "language"
    FROM files_with_content
)
GROUP BY "language"
ORDER BY "file_cnt" DESC
LIMIT 10;