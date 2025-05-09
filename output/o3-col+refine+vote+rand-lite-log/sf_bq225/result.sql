SELECT
    "language",
    COUNT(*) AS "file_count"
FROM (
    SELECT
        CASE LOWER(REGEXP_SUBSTR(f."path", '\\.([^.\\/]+)$', 1, 1, 'e'))
            WHEN 'asm'   THEN 'Assembly'
            WHEN 'nasm'  THEN 'Assembly'
            WHEN 'c'     THEN 'C'
            WHEN 'h'     THEN 'C'
            WHEN 'cs'    THEN 'C#'
            WHEN 'cpp'   THEN 'C++'
            WHEN 'c++'   THEN 'C++'
            WHEN 'hpp'   THEN 'C++'
            WHEN 'h++'   THEN 'C++'
            WHEN 'css'   THEN 'CSS'
            WHEN 'clj'   THEN 'Clojure'
            WHEN 'lisp'  THEN 'Common Lisp'
            WHEN 'd'     THEN 'D'
            WHEN 'dart'  THEN 'Dart'
            WHEN 'dockerfile' THEN 'Dockerfile'
            WHEN 'ex'    THEN 'Elixir'
            WHEN 'exs'   THEN 'Elixir'
            WHEN 'erl'   THEN 'Erlang'
            WHEN 'go'    THEN 'Go'
            WHEN 'groovy' THEN 'Groovy'
            WHEN 'html'  THEN 'HTML'
            WHEN 'htm'   THEN 'HTML'
            WHEN 'hs'    THEN 'Haskell'
            WHEN 'hx'    THEN 'Haxe'
            WHEN 'json'  THEN 'JSON'
            WHEN 'java'  THEN 'Java'
            WHEN 'js'    THEN 'JavaScript'
            WHEN 'cjs'   THEN 'JavaScript'
            WHEN 'jl'    THEN 'Julia'
            WHEN 'kt'    THEN 'Kotlin'
            WHEN 'ktm'   THEN 'Kotlin'
            WHEN 'kts'   THEN 'Kotlin'
            WHEN 'lua'   THEN 'Lua'
            WHEN 'matlab' THEN 'MATLAB'
            WHEN 'm'     THEN 'MATLAB'
            WHEN 'md'    THEN 'Markdown'
            WHEN 'markdown' THEN 'Markdown'
            WHEN 'mdown' THEN 'Markdown'
            WHEN 'php'   THEN 'PHP'
            WHEN 'ps1'   THEN 'PowerShell'
            WHEN 'psd1'  THEN 'PowerShell'
            WHEN 'psm1'  THEN 'PowerShell'
            WHEN 'py'    THEN 'Python'
            WHEN 'r'     THEN 'R'
            WHEN 'rb'    THEN 'Ruby'
            WHEN 'rs'    THEN 'Rust'
            WHEN 'scss'  THEN 'SCSS'
            WHEN 'sql'   THEN 'SQL'
            WHEN 'sass'  THEN 'Sass'
            WHEN 'scala' THEN 'Scala'
            WHEN 'sh'    THEN 'Shell'
            WHEN 'bash'  THEN 'Shell'
            WHEN 'swift' THEN 'Swift'
            WHEN 'ts'    THEN 'TypeScript'
            WHEN 'vue'   THEN 'Vue'
            WHEN 'xml'   THEN 'XML'
            WHEN 'yml'   THEN 'YAML'
            WHEN 'yaml'  THEN 'YAML'
            ELSE NULL
        END AS "language"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     AS f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  AS c
      ON f."id" = c."id"
    WHERE c."content" IS NOT NULL
) src
WHERE "language" IS NOT NULL
GROUP BY "language"
ORDER BY "file_count" DESC NULLS LAST
LIMIT 10;