WITH joined AS (  -- files that actually have non-empty content
    SELECT
        LOWER(REGEXP_SUBSTR(c."sample_path", '[^/]+$')) AS "FILENAME"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
          ON c."id" = f."id"
    WHERE c."content" IS NOT NULL
      AND LENGTH(c."content") > 0
), ext AS (        -- pull out the extension (if any)
    SELECT
        "FILENAME",
        LOWER(
            REGEXP_SUBSTR("FILENAME", '\\.([^.]+)$', 1, 1, 'e', 1)
        ) AS "EXT"
    FROM joined
), classified AS ( -- map filename / extension to language
    SELECT
        CASE
            WHEN "FILENAME" = 'dockerfile'
                 OR "FILENAME" LIKE '%.dockerfile'                   THEN 'Dockerfile'
            WHEN "EXT" IN ('asm','nasm')                            THEN 'Assembly'
            WHEN "EXT" IN ('c','h')                                 THEN 'C'
            WHEN "EXT" =  'cs'                                      THEN 'C#'
            WHEN "EXT" IN ('cpp','c++','hpp','h++')                 THEN 'C++'
            WHEN "EXT" =  'css'                                     THEN 'CSS'
            WHEN "EXT" =  'clj'                                     THEN 'Clojure'
            WHEN "EXT" =  'lisp'                                    THEN 'Common Lisp'
            WHEN "EXT" =  'd'                                       THEN 'D'
            WHEN "EXT" =  'dart'                                    THEN 'Dart'
            WHEN "EXT" IN ('ex','exs')                              THEN 'Elixir'
            WHEN "EXT" =  'erl'                                     THEN 'Erlang'
            WHEN "EXT" =  'go'                                      THEN 'Go'
            WHEN "EXT" =  'groovy'                                  THEN 'Groovy'
            WHEN "EXT" IN ('html','htm')                            THEN 'HTML'
            WHEN "EXT" =  'hs'                                      THEN 'Haskell'
            WHEN "EXT" =  'hx'                                      THEN 'Haxe'
            WHEN "EXT" =  'json'                                    THEN 'JSON'
            WHEN "EXT" =  'java'                                    THEN 'Java'
            WHEN "EXT" IN ('js','cjs')                              THEN 'JavaScript'
            WHEN "EXT" =  'jl'                                      THEN 'Julia'
            WHEN "EXT" IN ('kt','ktm','kts')                        THEN 'Kotlin'
            WHEN "EXT" =  'lua'                                     THEN 'Lua'
            WHEN "EXT" IN ('matlab','m')                            THEN 'MATLAB'
            WHEN "EXT" IN ('md','markdown','mdown')                 THEN 'Markdown'
            WHEN "EXT" =  'php'                                     THEN 'PHP'
            WHEN "EXT" IN ('ps1','psd1','psm1')                     THEN 'PowerShell'
            WHEN "EXT" =  'py'                                      THEN 'Python'
            WHEN "EXT" =  'r'                                       THEN 'R'
            WHEN "EXT" =  'rb'                                      THEN 'Ruby'
            WHEN "EXT" =  'rs'                                      THEN 'Rust'
            WHEN "EXT" =  'scss'                                    THEN 'SCSS'
            WHEN "EXT" =  'sql'                                     THEN 'SQL'
            WHEN "EXT" =  'sass'                                    THEN 'Sass'
            WHEN "EXT" =  'scala'                                   THEN 'Scala'
            WHEN "EXT" IN ('sh','bash')                             THEN 'Shell'
            WHEN "EXT" =  'swift'                                   THEN 'Swift'
            WHEN "EXT" =  'ts'                                      THEN 'TypeScript'
            WHEN "EXT" =  'vue'                                     THEN 'Vue'
            WHEN "EXT" =  'xml'                                     THEN 'XML'
            WHEN "EXT" IN ('yml','yaml')                            THEN 'YAML'
        END AS "LANGUAGE"
    FROM ext
)
SELECT
    "LANGUAGE",
    COUNT(*) AS "FILE_COUNT"
FROM classified
WHERE "LANGUAGE" IS NOT NULL
GROUP BY "LANGUAGE"
ORDER BY "FILE_COUNT" DESC NULLS LAST
FETCH 10 ROWS;