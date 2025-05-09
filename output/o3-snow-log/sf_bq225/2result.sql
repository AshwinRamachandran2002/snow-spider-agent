SELECT
    language,
    COUNT(*) AS file_count
FROM (
    SELECT
        CASE
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.(asm|nasm)$')                               THEN 'Assembly'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.(c|h)$')                                   THEN 'C'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.cs$')                                      THEN 'C#'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.(cpp|c\+\+|hpp|h\+\+)$')                   THEN 'C++'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.css$')                                     THEN 'CSS'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.clj$')                                     THEN 'Clojure'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.lisp$')                                    THEN 'Common Lisp'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.d$')                                       THEN 'D'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.dart$')                                    THEN 'Dart'
            WHEN LOWER("sample_path") LIKE '%/dockerfile' OR REGEXP_LIKE(LOWER("sample_path"), '\.dockerfile$') THEN 'Dockerfile'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.exs?$')                                    THEN 'Elixir'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.erl$')                                     THEN 'Erlang'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.go$')                                      THEN 'Go'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.groovy$')                                  THEN 'Groovy'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.html?$')                                   THEN 'HTML'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.hs$')                                      THEN 'Haskell'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.hx$')                                      THEN 'Haxe'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.json$')                                    THEN 'JSON'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.java$')                                    THEN 'Java'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.(js|cjs)$')                                THEN 'JavaScript'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.jl$')                                      THEN 'Julia'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.(kt|ktm|kts)$')                            THEN 'Kotlin'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.lua$')                                     THEN 'Lua'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.(matlab|m)$')                              THEN 'MATLAB'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.(md|markdown|mdown)$')                     THEN 'Markdown'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.php$')                                     THEN 'PHP'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.(ps1|psd1|psm1)$')                         THEN 'PowerShell'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.py$')                                      THEN 'Python'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.r$')                                       THEN 'R'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.rb$')                                      THEN 'Ruby'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.rs$')                                      THEN 'Rust'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.scss$')                                    THEN 'SCSS'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.sql$')                                     THEN 'SQL'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.sass$')                                    THEN 'Sass'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.scala$')                                   THEN 'Scala'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.(sh|bash)$')                               THEN 'Shell'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.swift$')                                   THEN 'Swift'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.ts$')                                      THEN 'TypeScript'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.vue$')                                     THEN 'Vue'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.xml$')                                     THEN 'XML'
            WHEN REGEXP_LIKE(LOWER("sample_path"), '\.ya?ml$')                                   THEN 'YAML'
            ELSE NULL
        END AS language
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "content" IS NOT NULL
      AND LENGTH("content") > 0
) AS lang_mapped
WHERE language IS NOT NULL
GROUP BY language
ORDER BY file_count DESC NULLS LAST
LIMIT 10;