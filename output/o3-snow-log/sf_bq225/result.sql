WITH combined AS (                                 -- files that have content
    SELECT f."id",
           f."path"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
           ON f."id" = c."id"
    WHERE  c."content" IS NOT NULL
),
classified AS (                                    -- file → language
    SELECT
        CASE
            WHEN "path" ILIKE '%/Dockerfile'          OR "path" ILIKE '%.dockerfile'    THEN 'Dockerfile'
            WHEN "path" ILIKE '%.asm'                 OR "path" ILIKE '%.nasm'         THEN 'Assembly'
            WHEN "path" ILIKE '%.c'                   OR "path" ILIKE '%.h'            THEN 'C'
            WHEN "path" ILIKE '%.c++'                 OR "path" ILIKE '%.cpp'
                 OR "path" ILIKE '%.h++'              OR "path" ILIKE '%.hpp'          THEN 'C++'
            WHEN "path" ILIKE '%.cs'                                                     THEN 'C#'
            WHEN "path" ILIKE '%.css'                                                    THEN 'CSS'
            WHEN "path" ILIKE '%.clj'                                                    THEN 'Clojure'
            WHEN "path" ILIKE '%.lisp'                                                  THEN 'Common Lisp'
            WHEN "path" ILIKE '%.d'                                                     THEN 'D'
            WHEN "path" ILIKE '%.dart'                                                  THEN 'Dart'
            WHEN "path" ILIKE '%.ex'   OR "path" ILIKE '%.exs'                          THEN 'Elixir'
            WHEN "path" ILIKE '%.erl'                                                   THEN 'Erlang'
            WHEN "path" ILIKE '%.go'                                                    THEN 'Go'
            WHEN "path" ILIKE '%.groovy'                                                THEN 'Groovy'
            WHEN "path" ILIKE '%.htm'  OR "path" ILIKE '%.html'                         THEN 'HTML'
            WHEN "path" ILIKE '%.hs'                                                    THEN 'Haskell'
            WHEN "path" ILIKE '%.hx'                                                    THEN 'Haxe'
            WHEN "path" ILIKE '%.json'                                                  THEN 'JSON'
            WHEN "path" ILIKE '%.java'                                                  THEN 'Java'
            WHEN "path" ILIKE '%.js'   OR "path" ILIKE '%.cjs'                          THEN 'JavaScript'
            WHEN "path" ILIKE '%.jl'                                                    THEN 'Julia'
            WHEN "path" ILIKE '%.kt'   OR "path" ILIKE '%.ktm' OR "path" ILIKE '%.kts'  THEN 'Kotlin'
            WHEN "path" ILIKE '%.lua'                                                   THEN 'Lua'
            WHEN "path" ILIKE '%.m'    OR "path" ILIKE '%.matlab'                       THEN 'MATLAB'
            WHEN "path" ILIKE '%.md'   OR "path" ILIKE '%.markdown' OR "path" ILIKE '%.mdown' THEN 'Markdown'
            WHEN "path" ILIKE '%.php'                                                   THEN 'PHP'
            WHEN "path" ILIKE '%.ps1'  OR "path" ILIKE '%.psd1' OR "path" ILIKE '%.psm1' THEN 'PowerShell'
            WHEN "path" ILIKE '%.py'                                                    THEN 'Python'
            WHEN "path" ILIKE '%.r'                                                     THEN 'R'
            WHEN "path" ILIKE '%.rb'                                                    THEN 'Ruby'
            WHEN "path" ILIKE '%.rs'                                                    THEN 'Rust'
            WHEN "path" ILIKE '%.scss'                                                 THEN 'SCSS'
            WHEN "path" ILIKE '%.sql'                                                  THEN 'SQL'
            WHEN "path" ILIKE '%.sass'                                                 THEN 'Sass'
            WHEN "path" ILIKE '%.scala'                                                THEN 'Scala'
            WHEN "path" ILIKE '%.sh'   OR "path" ILIKE '%.bash'                        THEN 'Shell'
            WHEN "path" ILIKE '%.swift'                                                THEN 'Swift'
            WHEN "path" ILIKE '%.ts'                                                   THEN 'TypeScript'
            WHEN "path" ILIKE '%.vue'                                                  THEN 'Vue'
            WHEN "path" ILIKE '%.xml'                                                  THEN 'XML'
            WHEN "path" ILIKE '%.yml'  OR "path" ILIKE '%.yaml'                        THEN 'YAML'
        END AS language
    FROM combined
),
lang_counts AS (                                   -- count files per language
    SELECT language,
           COUNT(*) AS file_count
    FROM   classified
    WHERE  language IS NOT NULL
    GROUP BY language
)
SELECT language,
       file_count
FROM   lang_counts
ORDER BY file_count DESC NULLS LAST
LIMIT 10;