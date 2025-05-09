WITH files_with_content AS (
    SELECT
        COALESCE(f."path", c."sample_path") AS file_path
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
    LEFT JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
           ON f."id" = c."id"
    WHERE c."content" IS NOT NULL
      AND LENGTH(c."content") > 0
      AND COALESCE(f."path", c."sample_path") IS NOT NULL
),
classified AS (
    SELECT
        CASE
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(asm|nasm)$')                                     THEN 'Assembly'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(c|h)$')                                          THEN 'C'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(cs)$')                                           THEN 'C#'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(c\+\+|cpp|h\+\+|hpp)$')                          THEN 'C++'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(css)$')                                          THEN 'CSS'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(clj)$')                                          THEN 'Clojure'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(lisp)$')                                         THEN 'Common Lisp'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(d)$')                                            THEN 'D'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(dart)$')                                         THEN 'Dart'
            WHEN REGEXP_LIKE(LOWER(file_path), '(^|/)(dockerfile)$')                                 
              OR REGEXP_LIKE(LOWER(file_path), '\.dockerfile$')                                     THEN 'Dockerfile'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(ex|exs)$')                                       THEN 'Elixir'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(erl)$')                                          THEN 'Erlang'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(go)$')                                           THEN 'Go'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(groovy)$')                                       THEN 'Groovy'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(html?|htm)$')                                    THEN 'HTML'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(hs)$')                                           THEN 'Haskell'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(hx)$')                                           THEN 'Haxe'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(json)$')                                         THEN 'JSON'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(java)$')                                         THEN 'Java'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(js|cjs)$')                                       THEN 'JavaScript'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(jl)$')                                           THEN 'Julia'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(kt|ktm|kts)$')                                   THEN 'Kotlin'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(lua)$')                                          THEN 'Lua'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(matlab|m)$')                                     THEN 'MATLAB'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(md|markdown|mdown)$')                            THEN 'Markdown'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(php)$')                                          THEN 'PHP'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(ps1|psd1|psm1)$')                                THEN 'PowerShell'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(py)$')                                           THEN 'Python'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(r)$')                                            THEN 'R'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(rb)$')                                           THEN 'Ruby'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(rs)$')                                           THEN 'Rust'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(scss)$')                                         THEN 'SCSS'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(sql)$')                                          THEN 'SQL'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(sass)$')                                         THEN 'Sass'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(scala)$')                                        THEN 'Scala'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(sh|bash)$')                                      THEN 'Shell'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(swift)$')                                        THEN 'Swift'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(ts)$')                                           THEN 'TypeScript'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(vue)$')                                          THEN 'Vue'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(xml)$')                                          THEN 'XML'
            WHEN REGEXP_LIKE(LOWER(file_path), '\.(yml|yaml)$')                                     THEN 'YAML'
            ELSE NULL
        END AS language
    FROM files_with_content
)
SELECT
    language,
    COUNT(*) AS file_count
FROM classified
WHERE language IS NOT NULL
GROUP BY language
ORDER BY file_count DESC NULLS LAST
LIMIT 10;