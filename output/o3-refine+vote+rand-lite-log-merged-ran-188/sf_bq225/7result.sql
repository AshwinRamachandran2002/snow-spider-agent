SELECT
    language,
    COUNT(*) AS file_count
FROM (
    SELECT
        CASE
            /* Handle filenames without extensions first */
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) = 'dockerfile'
                 OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.dockerfile'          THEN 'Dockerfile'
            
            /* Longer / more‑specific extensions before the shorter ones to avoid mis‑matches */
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.c++'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.cpp'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.h++'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.hpp'                    THEN 'C++'
            
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.ps1'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.psd1'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.psm1'                   THEN 'PowerShell'
            
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.markdown'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.mdown'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.md'                     THEN 'Markdown'
            
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.asm'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.nasm'                   THEN 'Assembly'
            
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.scss'                   THEN 'SCSS'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.swift'                  THEN 'Swift'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.scala'                  THEN 'Scala'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.typescript'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.ts'                     THEN 'TypeScript'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.java'                   THEN 'Java'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.kt'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.ktm'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.kts'                    THEN 'Kotlin'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.dart'                   THEN 'Dart'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.json'                   THEN 'JSON'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.html'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.htm'                    THEN 'HTML'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.css'                    THEN 'CSS'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.js'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.cjs'                    THEN 'JavaScript'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.py'                     THEN 'Python'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.rb'                     THEN 'Ruby'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.go'                     THEN 'Go'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.rs'                     THEN 'Rust'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.php'                    THEN 'PHP'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.lua'                    THEN 'Lua'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.ex'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.exs'                    THEN 'Elixir'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.erl'                    THEN 'Erlang'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.groovy'                 THEN 'Groovy'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.hx'                     THEN 'Haxe'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.hs'                     THEN 'Haskell'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.jl'                     THEN 'Julia'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.clj'                    THEN 'Clojure'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.lisp'                   THEN 'Common Lisp'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.yaml'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.yml'                    THEN 'YAML'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.xml'                    THEN 'XML'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.sql'                    THEN 'SQL'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.sass'                   THEN 'Sass'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.r'                      THEN 'R'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.ps1'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.psd1'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.psm1'                   THEN 'PowerShell'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.sh'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.bash'                   THEN 'Shell'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.vue'                    THEN 'Vue'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.matlab'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.m'                      THEN 'MATLAB'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.cs'                     THEN 'C#'
            
            /* keep generic single‑character extensions last (C, D, etc.) */
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.c'
              OR LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.h'                      THEN 'C'
            WHEN LOWER(SPLIT_PART(f."path", '/', -1)) LIKE '%.d'                      THEN 'D'
            
        END AS language
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES      AS f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS   AS c
          ON f."id" = c."id"
    WHERE c."content" IS NOT NULL
      AND LENGTH(TRIM(c."content")) > 0
) sub
WHERE language IS NOT NULL
GROUP BY language
ORDER BY file_count DESC NULLS LAST, language
LIMIT 10;