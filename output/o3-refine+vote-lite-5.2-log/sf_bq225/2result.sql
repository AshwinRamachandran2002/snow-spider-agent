SELECT
    language,
    COUNT(*) AS file_count
FROM (
    SELECT
        CASE
            WHEN LOWER(f."path") LIKE '%.asm'  OR LOWER(f."path") LIKE '%.nasm'                  THEN 'Assembly'
            WHEN LOWER(f."path") LIKE '%.c'                                                     THEN 'C'
            WHEN LOWER(f."path") LIKE '%.cs'                                                    THEN 'C#'
            WHEN LOWER(f."path") LIKE '%.c++' OR LOWER(f."path") LIKE '%.cpp'
                 OR LOWER(f."path") LIKE '%.h++' OR LOWER(f."path") LIKE '%.hpp'                THEN 'C++'
            WHEN LOWER(f."path") LIKE '%.css'                                                   THEN 'CSS'
            WHEN LOWER(f."path") LIKE '%.clj'                                                   THEN 'Clojure'
            WHEN LOWER(f."path") LIKE '%.lisp'                                                  THEN 'Common Lisp'
            WHEN LOWER(f."path") LIKE '%.d'                                                     THEN 'D'
            WHEN LOWER(f."path") LIKE '%.dart'                                                  THEN 'Dart'
            WHEN LOWER(f."path") LIKE '%/dockerfile' OR LOWER(f."path") LIKE 'dockerfile'
                 OR LOWER(f."path") LIKE '%.dockerfile'                                         THEN 'Dockerfile'
            WHEN LOWER(f."path") LIKE '%.ex'  OR LOWER(f."path") LIKE '%.exs'                   THEN 'Elixir'
            WHEN LOWER(f."path") LIKE '%.erl'                                                   THEN 'Erlang'
            WHEN LOWER(f."path") LIKE '%.go'                                                    THEN 'Go'
            WHEN LOWER(f."path") LIKE '%.groovy'                                                THEN 'Groovy'
            WHEN LOWER(f."path") LIKE '%.html' OR LOWER(f."path") LIKE '%.htm'                  THEN 'HTML'
            WHEN LOWER(f."path") LIKE '%.hs'                                                    THEN 'Haskell'
            WHEN LOWER(f."path") LIKE '%.hx'                                                    THEN 'Haxe'
            WHEN LOWER(f."path") LIKE '%.json'                                                  THEN 'JSON'
            WHEN LOWER(f."path") LIKE '%.java'                                                  THEN 'Java'
            WHEN LOWER(f."path") LIKE '%.js'  OR LOWER(f."path") LIKE '%.cjs'                   THEN 'JavaScript'
            WHEN LOWER(f."path") LIKE '%.jl'                                                    THEN 'Julia'
            WHEN LOWER(f."path") LIKE '%.kt'  OR LOWER(f."path") LIKE '%.ktm'
                 OR LOWER(f."path") LIKE '%.kts'                                                THEN 'Kotlin'
            WHEN LOWER(f."path") LIKE '%.lua'                                                   THEN 'Lua'
            WHEN LOWER(f."path") LIKE '%.matlab' OR LOWER(f."path") LIKE '%.m'                  THEN 'MATLAB'
            WHEN LOWER(f."path") LIKE '%.md'  OR LOWER(f."path") LIKE '%.markdown'
                 OR LOWER(f."path") LIKE '%.mdown'                                              THEN 'Markdown'
            WHEN LOWER(f."path") LIKE '%.php'                                                   THEN 'PHP'
            WHEN LOWER(f."path") LIKE '%.ps1' OR LOWER(f."path") LIKE '%.psd1'
                 OR LOWER(f."path") LIKE '%.psm1'                                               THEN 'PowerShell'
            WHEN LOWER(f."path") LIKE '%.py'                                                    THEN 'Python'
            WHEN LOWER(f."path") LIKE '%.r'                                                     THEN 'R'
            WHEN LOWER(f."path") LIKE '%.rb'                                                    THEN 'Ruby'
            WHEN LOWER(f."path") LIKE '%.rs'                                                    THEN 'Rust'
            WHEN LOWER(f."path") LIKE '%.scss'                                                  THEN 'SCSS'
            WHEN LOWER(f."path") LIKE '%.sql'                                                   THEN 'SQL'
            WHEN LOWER(f."path") LIKE '%.sass'                                                  THEN 'Sass'
            WHEN LOWER(f."path") LIKE '%.scala'                                                 THEN 'Scala'
            WHEN LOWER(f."path") LIKE '%.sh'  OR LOWER(f."path") LIKE '%.bash'                  THEN 'Shell'
            WHEN LOWER(f."path") LIKE '%.swift'                                                 THEN 'Swift'
            WHEN LOWER(f."path") LIKE '%.ts'                                                    THEN 'TypeScript'
            WHEN LOWER(f."path") LIKE '%.vue'                                                   THEN 'Vue'
            WHEN LOWER(f."path") LIKE '%.xml'                                                   THEN 'XML'
            WHEN LOWER(f."path") LIKE '%.yml' OR LOWER(f."path") LIKE '%.yaml'                  THEN 'YAML'
        END AS language
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"   AS f
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" AS c
          ON c."id" = f."id"
    WHERE c."content" IS NOT NULL
      AND LENGTH(TRIM(c."content")) > 0
) sub
WHERE language IS NOT NULL
GROUP BY language
ORDER BY file_count DESC NULLS LAST, language
LIMIT 10;