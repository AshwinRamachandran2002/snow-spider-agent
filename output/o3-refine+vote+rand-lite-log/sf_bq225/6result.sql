WITH files AS (
    /*  files that have non–empty content  */
    SELECT
        f."path"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
          ON c."id" = f."id"
    WHERE c."content" IS NOT NULL
      AND LENGTH(c."content") > 0
),
exts AS (
    /*  helper columns: file‑name and extension (both lower‑cased) */
    SELECT
        "path",
        LOWER(SPLIT_PART("path", '/', -1))                    AS filename,
        LOWER(SPLIT_PART("path", '.', -1))                    AS ext
    FROM files
),
mapped AS (
    /*  map every file to one of the recognised languages  */
    SELECT
        CASE
            WHEN filename = 'dockerfile' OR ext = 'dockerfile'                        THEN 'Dockerfile'
            WHEN ext IN ('asm','nasm')                                                THEN 'Assembly'
            WHEN ext IN ('c','h')                                                     THEN 'C'
            WHEN ext = 'cs'                                                           THEN 'C#'
            WHEN ext IN ('cpp','c++','hpp','h++')                                     THEN 'C++'
            WHEN ext = 'css'                                                          THEN 'CSS'
            WHEN ext = 'clj'                                                          THEN 'Clojure'
            WHEN ext = 'lisp'                                                         THEN 'Common Lisp'
            WHEN ext = 'd'                                                            THEN 'D'
            WHEN ext = 'dart'                                                         THEN 'Dart'
            WHEN ext IN ('ex','exs')                                                  THEN 'Elixir'
            WHEN ext = 'erl'                                                          THEN 'Erlang'
            WHEN ext = 'go'                                                           THEN 'Go'
            WHEN ext = 'groovy'                                                       THEN 'Groovy'
            WHEN ext IN ('html','htm')                                                THEN 'HTML'
            WHEN ext = 'hs'                                                           THEN 'Haskell'
            WHEN ext = 'hx'                                                           THEN 'Haxe'
            WHEN ext = 'json'                                                         THEN 'JSON'
            WHEN ext = 'java'                                                         THEN 'Java'
            WHEN ext IN ('js','cjs')                                                  THEN 'JavaScript'
            WHEN ext = 'jl'                                                           THEN 'Julia'
            WHEN ext IN ('kt','ktm','kts')                                            THEN 'Kotlin'
            WHEN ext = 'lua'                                                          THEN 'Lua'
            WHEN ext IN ('matlab','m')                                                THEN 'MATLAB'
            WHEN ext IN ('md','markdown','mdown')                                     THEN 'Markdown'
            WHEN ext = 'php'                                                          THEN 'PHP'
            WHEN ext IN ('ps1','psd1','psm1')                                         THEN 'PowerShell'
            WHEN ext = 'py'                                                           THEN 'Python'
            WHEN ext = 'r'                                                            THEN 'R'
            WHEN ext = 'rb'                                                           THEN 'Ruby'
            WHEN ext = 'rs'                                                           THEN 'Rust'
            WHEN ext = 'scss'                                                         THEN 'SCSS'
            WHEN ext = 'sql'                                                          THEN 'SQL'
            WHEN ext = 'sass'                                                         THEN 'Sass'
            WHEN ext = 'scala'                                                        THEN 'Scala'
            WHEN ext IN ('sh','bash')                                                 THEN 'Shell'
            WHEN ext = 'swift'                                                        THEN 'Swift'
            WHEN ext = 'ts'                                                           THEN 'TypeScript'
            WHEN ext = 'vue'                                                          THEN 'Vue'
            WHEN ext = 'xml'                                                          THEN 'XML'
            WHEN ext IN ('yml','yaml')                                                THEN 'YAML'
        END AS language
    FROM exts
)
SELECT
    language,
    COUNT(*) AS file_count
FROM mapped
WHERE language IS NOT NULL
GROUP BY language
ORDER BY file_count DESC NULLS LAST, language
LIMIT 10;