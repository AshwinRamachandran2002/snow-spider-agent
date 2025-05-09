SELECT
    language,
    COUNT(*) AS file_count
FROM (
    SELECT
        CASE
            /* special case first */
            WHEN lower(file_name) = 'dockerfile'
                 OR lower(file_name) LIKE '%.dockerfile'          THEN 'Dockerfile'

            /* longer / more‑specific extensions before shorter ones */
            WHEN lower(file_name) LIKE '%.c++'  OR lower(file_name) LIKE '%.cpp'
              OR lower(file_name) LIKE '%.h++'  OR lower(file_name) LIKE '%.hpp' THEN 'C++'
            WHEN lower(file_name) LIKE '%.asm'  OR lower(file_name) LIKE '%.nasm'        THEN 'Assembly'
            WHEN lower(file_name) LIKE '%.cs'                                               THEN 'C#'
            WHEN lower(file_name) LIKE '%.css'                                              THEN 'CSS'
            WHEN lower(file_name) LIKE '%.clj'                                              THEN 'Clojure'
            WHEN lower(file_name) LIKE '%.lisp'                                             THEN 'Common Lisp'
            WHEN lower(file_name) LIKE '%.d'                                                THEN 'D'
            WHEN lower(file_name) LIKE '%.dart'                                             THEN 'Dart'
            WHEN lower(file_name) LIKE '%.ex'  OR lower(file_name) LIKE '%.exs'             THEN 'Elixir'
            WHEN lower(file_name) LIKE '%.erl'                                              THEN 'Erlang'
            WHEN lower(file_name) LIKE '%.go'                                               THEN 'Go'
            WHEN lower(file_name) LIKE '%.groovy'                                           THEN 'Groovy'
            WHEN lower(file_name) LIKE '%.html' OR lower(file_name) LIKE '%.htm'            THEN 'HTML'
            WHEN lower(file_name) LIKE '%.hs'                                               THEN 'Haskell'
            WHEN lower(file_name) LIKE '%.hx'                                               THEN 'Haxe'
            WHEN lower(file_name) LIKE '%.json'                                             THEN 'JSON'
            WHEN lower(file_name) LIKE '%.java'                                             THEN 'Java'
            WHEN lower(file_name) LIKE '%.js'  OR lower(file_name) LIKE '%.cjs'             THEN 'JavaScript'
            WHEN lower(file_name) LIKE '%.jl'                                               THEN 'Julia'
            WHEN lower(file_name) LIKE '%.kt'  OR lower(file_name) LIKE '%.ktm'
              OR lower(file_name) LIKE '%.kts'                                             THEN 'Kotlin'
            WHEN lower(file_name) LIKE '%.lua'                                              THEN 'Lua'
            WHEN lower(file_name) LIKE '%.matlab' OR lower(file_name) LIKE '%.m'            THEN 'MATLAB'
            WHEN lower(file_name) LIKE '%.md'  OR lower(file_name) LIKE '%.markdown'
              OR lower(file_name) LIKE '%.mdown'                                           THEN 'Markdown'
            WHEN lower(file_name) LIKE '%.php'                                              THEN 'PHP'
            WHEN lower(file_name) LIKE '%.ps1' OR lower(file_name) LIKE '%.psd1'
              OR lower(file_name) LIKE '%.psm1'                                            THEN 'PowerShell'
            WHEN lower(file_name) LIKE '%.py'                                               THEN 'Python'
            WHEN lower(file_name) LIKE '%.r'                                                THEN 'R'
            WHEN lower(file_name) LIKE '%.rb'                                               THEN 'Ruby'
            WHEN lower(file_name) LIKE '%.rs'                                               THEN 'Rust'
            WHEN lower(file_name) LIKE '%.scss'                                             THEN 'SCSS'
            WHEN lower(file_name) LIKE '%.sql'                                              THEN 'SQL'
            WHEN lower(file_name) LIKE '%.sass'                                             THEN 'Sass'
            WHEN lower(file_name) LIKE '%.scala'                                            THEN 'Scala'
            WHEN lower(file_name) LIKE '%.sh'  OR lower(file_name) LIKE '%.bash'            THEN 'Shell'
            WHEN lower(file_name) LIKE '%.swift'                                            THEN 'Swift'
            WHEN lower(file_name) LIKE '%.ts'                                               THEN 'TypeScript'
            WHEN lower(file_name) LIKE '%.vue'                                              THEN 'Vue'
            WHEN lower(file_name) LIKE '%.xml'                                              THEN 'XML'
            WHEN lower(file_name) LIKE '%.yml' OR lower(file_name) LIKE '%.yaml'            THEN 'YAML'
            /* C must come after C++ to avoid double‑counting */
            WHEN lower(file_name) LIKE '%.c'   OR lower(file_name) LIKE '%.h'               THEN 'C'
            ELSE NULL
        END AS language
    FROM (
        SELECT
            f."path"                                        AS file_path,
            SPLIT_PART(f."path", '/', -1)                   AS file_name
        FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
        JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
              ON c."id" = f."id"
        WHERE c."content" IS NOT NULL
          AND LENGTH(TRIM(c."content")) > 0
    )
)
WHERE language IS NOT NULL
GROUP BY language
ORDER BY file_count DESC NULLS LAST, language
LIMIT 10;