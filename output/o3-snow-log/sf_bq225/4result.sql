WITH files_with_content AS (
    SELECT
        LOWER(f."path")       AS path_lower,
        c."content"
    FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"     f
    JOIN   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  c
           ON f."id" = c."id"
    WHERE  c."content" IS NOT NULL
      AND  LENGTH(TRIM(c."content")) > 0          -- non-empty content
), classified AS (
    SELECT
        CASE
            WHEN path_lower LIKE '%.asm'        OR path_lower LIKE '%.nasm'                       THEN 'Assembly'
            WHEN path_lower LIKE '%.c'                                                         THEN 'C'
            WHEN path_lower LIKE '%.cs'                                                        THEN 'C#'
            WHEN path_lower LIKE '%.cpp' OR path_lower LIKE '%.c++'
              OR path_lower LIKE '%.hpp' OR path_lower LIKE '%.h++'                             THEN 'C++'
            WHEN path_lower LIKE '%.css'                                                       THEN 'CSS'
            WHEN path_lower LIKE '%.clj'                                                       THEN 'Clojure'
            WHEN path_lower LIKE '%.lisp'                                                      THEN 'Common Lisp'
            WHEN path_lower LIKE '%.d'                                                         THEN 'D'
            WHEN path_lower LIKE '%.dart'                                                      THEN 'Dart'
            WHEN path_lower LIKE '%dockerfile'                                                 THEN 'Dockerfile'
            WHEN path_lower LIKE '%.ex'  OR path_lower LIKE '%.exs'                             THEN 'Elixir'
            WHEN path_lower LIKE '%.erl'                                                       THEN 'Erlang'
            WHEN path_lower LIKE '%.go'                                                        THEN 'Go'
            WHEN path_lower LIKE '%.groovy'                                                    THEN 'Groovy'
            WHEN path_lower LIKE '%.html' OR path_lower LIKE '%.htm'                            THEN 'HTML'
            WHEN path_lower LIKE '%.hs'                                                        THEN 'Haskell'
            WHEN path_lower LIKE '%.hx'                                                        THEN 'Haxe'
            WHEN path_lower LIKE '%.json'                                                      THEN 'JSON'
            WHEN path_lower LIKE '%.java'                                                      THEN 'Java'
            WHEN path_lower LIKE '%.js'  OR path_lower LIKE '%.cjs'                             THEN 'JavaScript'
            WHEN path_lower LIKE '%.jl'                                                        THEN 'Julia'
            WHEN path_lower LIKE '%.kt'  OR path_lower LIKE '%.ktm' OR path_lower LIKE '%.kts'  THEN 'Kotlin'
            WHEN path_lower LIKE '%.lua'                                                       THEN 'Lua'
            WHEN path_lower LIKE '%.matlab' OR path_lower LIKE '%.m'                            THEN 'MATLAB'
            WHEN path_lower LIKE '%.md'  OR path_lower LIKE '%.markdown' OR path_lower LIKE '%.mdown' THEN 'Markdown'
            WHEN path_lower LIKE '%.php'                                                       THEN 'PHP'
            WHEN path_lower LIKE '%.ps1' OR path_lower LIKE '%.psd1' OR path_lower LIKE '%.psm1' THEN 'PowerShell'
            WHEN path_lower LIKE '%.py'                                                        THEN 'Python'
            WHEN path_lower LIKE '%.r'                                                         THEN 'R'
            WHEN path_lower LIKE '%.rb'                                                        THEN 'Ruby'
            WHEN path_lower LIKE '%.rs'                                                        THEN 'Rust'
            WHEN path_lower LIKE '%.scss'                                                      THEN 'SCSS'
            WHEN path_lower LIKE '%.sql'                                                       THEN 'SQL'
            WHEN path_lower LIKE '%.sass'                                                      THEN 'Sass'
            WHEN path_lower LIKE '%.scala'                                                     THEN 'Scala'
            WHEN path_lower LIKE '%.sh'  OR path_lower LIKE '%.bash'                            THEN 'Shell'
            WHEN path_lower LIKE '%.swift'                                                     THEN 'Swift'
            WHEN path_lower LIKE '%.ts'                                                        THEN 'TypeScript'
            WHEN path_lower LIKE '%.vue'                                                       THEN 'Vue'
            WHEN path_lower LIKE '%.xml'                                                       THEN 'XML'
            WHEN path_lower LIKE '%.yml' OR path_lower LIKE '%.yaml'                            THEN 'YAML'
            ELSE NULL
        END AS language
    FROM files_with_content
)
SELECT
    language,
    COUNT(*) AS file_count
FROM   classified
WHERE  language IS NOT NULL
GROUP  BY language
ORDER  BY file_count DESC NULLS LAST
LIMIT  10;