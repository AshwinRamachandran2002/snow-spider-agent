WITH candidate_words AS (           -- 4-5 letters, start with lowercase r
    SELECT DISTINCT "words" AS word
    FROM MODERN_DATA.MODERN_DATA.WORD_LIST
    WHERE "words" LIKE 'r%' 
      AND LENGTH("words") BETWEEN 4 AND 5
),                                              
char_expanded AS (              -- explode each word into its characters
    SELECT 
        cw.word,
        SUBSTR(cw.word, g.seq + 1, 1) AS ch
    FROM candidate_words cw
    CROSS JOIN LATERAL (
        SELECT seq4() AS seq
        FROM TABLE(GENERATOR(ROWCOUNT => 5))   -- enough positions for 4-5 letters
    ) g
    WHERE g.seq < LENGTH(cw.word)
),                                              
signatures AS (                 -- build alphabetically-sorted “signature”
    SELECT
        word,
        LISTAGG(ch, '') WITHIN GROUP (ORDER BY ch) AS signature
    FROM char_expanded
    GROUP BY word
),                                              
anagram_groups AS (             -- keep only signatures with ≥2 words
    SELECT
        signature,
        COUNT(*) AS anagram_count
    FROM signatures
    GROUP BY signature
    HAVING COUNT(*) >= 2
)                                               
SELECT
    s.word,
    ag.anagram_count
FROM signatures       s
JOIN anagram_groups   ag  ON s.signature = ag.signature
ORDER BY s.word
LIMIT 10;