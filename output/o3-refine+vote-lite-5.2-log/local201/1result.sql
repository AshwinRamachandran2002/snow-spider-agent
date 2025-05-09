WITH
filtered AS (            -- 1. 4–5 letter words that start with “r”
    SELECT rowid AS id,
           words AS word
    FROM   word_list
    WHERE  length(words) BETWEEN 4 AND 5
      AND  substr(words,1,1) = 'r'
),
-- 2. split every kept word into one character‑per‑row
split(id,pos,ch) AS (
    SELECT id,
           1,
           substr(word,1,1)
    FROM   filtered
    UNION ALL
    SELECT s.id,
           s.pos + 1,
           substr(f.word, s.pos + 1, 1)
    FROM   split     s
    JOIN   filtered  f  ON f.id = s.id
    WHERE  s.pos + 1 <= length(f.word)
),
-- 3. build a sorted‑letter “signature” for each word
signatures AS (
    SELECT  f.id,
            f.word,
            (SELECT group_concat(ch,'')
             FROM   split s2
             WHERE  s2.id = f.id
             ORDER  BY ch) AS signature
    FROM    filtered f
),
-- 4. count how many words share each signature
anagrams AS (
    SELECT  a.word,
            (SELECT COUNT(*)
             FROM   signatures b
             WHERE  b.signature = a.signature) AS anagram_count
    FROM    signatures a
)
-- 5. first 10 alphabetically that have ≥2 anagrams
SELECT  word,
        anagram_count
FROM    anagrams
WHERE   anagram_count >= 2
ORDER BY word
LIMIT 10;