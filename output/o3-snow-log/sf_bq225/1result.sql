WITH joined AS (
    SELECT
        f."path"      AS path,
        c."content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
          ON f."id" = c."id"
    WHERE c."content" IS NOT NULL
      AND LENGTH(TRIM(c."content")) > 0
),
lang_files AS (
    SELECT
        CASE
            WHEN LOWER(REGEXP_REPLACE(path, '.*\/', '')) = 'dockerfile'
                 OR LOWER(path) LIKE '%.dockerfile'                      THEN 'Dockerfile'
            WHEN LOWER(path) LIKE '%.asm'   OR LOWER(path) LIKE '%.nasm' THEN 'Assembly'
            WHEN LOWER(path) LIKE '%.c++'   OR LOWER(path) LIKE '%.cpp'
              OR LOWER(path) LIKE '%.hpp'   OR LOWER(path) LIKE '%.h++'  THEN 'C++'
            WHEN LOWER(path) LIKE '%.c'     OR LOWER(path) LIKE '%.h'    THEN 'C'
            WHEN LOWER(path) LIKE '%.cs'                                  THEN 'C#'
            WHEN LOWER(path) LIKE '%.css'                                 THEN 'CSS'
            WHEN LOWER(path) LIKE '%.clj'                                 THEN 'Clojure'
            WHEN LOWER(path) LIKE '%.lisp'                                THEN 'Common Lisp'
            WHEN LOWER(path) LIKE '%.d'                                   THEN 'D'
            WHEN LOWER(path) LIKE '%.dart'                                THEN 'Dart'
            WHEN LOWER(path) LIKE '%.ex'    OR LOWER(path) LIKE '%.exs'   THEN 'Elixir'
            WHEN LOWER(path) LIKE '%.erl'                                 THEN 'Erlang'
            WHEN LOWER(path) LIKE '%.go'                                  THEN 'Go'
            WHEN LOWER(path) LIKE '%.groovy'                              THEN 'Groovy'
            WHEN LOWER(path) LIKE '%.html'  OR LOWER(path) LIKE '%.htm'   THEN 'HTML'
            WHEN LOWER(path) LIKE '%.hs'                                  THEN 'Haskell'
            WHEN LOWER(path) LIKE '%.hx'                                  THEN 'Haxe'
            WHEN LOWER(path) LIKE '%.json'                                THEN 'JSON'
            WHEN LOWER(path) LIKE '%.java'                                THEN 'Java'
            WHEN LOWER(path) LIKE '%.js'    OR LOWER(path) LIKE '%.cjs'   THEN 'JavaScript'
            WHEN LOWER(path) LIKE '%.jl'                                  THEN 'Julia'
            WHEN LOWER(path) LIKE '%.kt'    OR LOWER(path) LIKE '%.ktm'
              OR LOWER(path) LIKE '%.kts'                                 THEN 'Kotlin'
            WHEN LOWER(path) LIKE '%.lua'                                 THEN 'Lua'
            WHEN LOWER(path) LIKE '%.matlab' OR LOWER(path) LIKE '%.m'    THEN 'MATLAB'
            WHEN LOWER(path) LIKE '%.md'    OR LOWER(path) LIKE '%.markdown'
              OR LOWER(path) LIKE '%.mdown'                               THEN 'Markdown'
            WHEN LOWER(path) LIKE '%.php'                                 THEN 'PHP'
            WHEN LOWER(path) LIKE '%.ps1'   OR LOWER(path) LIKE '%.psd1'
              OR LOWER(path) LIKE '%.psm1'                                THEN 'PowerShell'
            WHEN LOWER(path) LIKE '%.py'                                  THEN 'Python'
            WHEN LOWER(path) LIKE '%.r'                                   THEN 'R'
            WHEN LOWER(path) LIKE '%.rb'                                  THEN 'Ruby'
            WHEN LOWER(path) LIKE '%.rs'                                  THEN 'Rust'
            WHEN LOWER(path) LIKE '%.scss'                                THEN 'SCSS'
            WHEN LOWER(path) LIKE '%.sql'                                 THEN 'SQL'
            WHEN LOWER(path) LIKE '%.sass'                                THEN 'Sass'
            WHEN LOWER(path) LIKE '%.scala'                               THEN 'Scala'
            WHEN LOWER(path) LIKE '%.sh'    OR LOWER(path) LIKE '%.bash'  THEN 'Shell'
            WHEN LOWER(path) LIKE '%.swift'                               THEN 'Swift'
            WHEN LOWER(path) LIKE '%.ts'                                  THEN 'TypeScript'
            WHEN LOWER(path) LIKE '%.vue'                                 THEN 'Vue'
            WHEN LOWER(path) LIKE '%.xml'                                 THEN 'XML'
            WHEN LOWER(path) LIKE '%.yml'   OR LOWER(path) LIKE '%.yaml'  THEN 'YAML'
            ELSE NULL
        END AS language
    FROM joined
)
SELECT
    language,
    COUNT(*) AS file_count
FROM lang_files
WHERE language IS NOT NULL
GROUP BY language
ORDER BY file_count DESC NULLS LAST
LIMIT 10;