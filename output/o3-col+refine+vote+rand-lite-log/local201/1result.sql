WITH RECURSIVE
    /* 1. keep every 4–5-letter word just once */
    base(word) AS (
        SELECT DISTINCT words
        FROM word_list
        WHERE length(words) BETWEEN 4 AND 5
    ),

    /* 2. split each word into its characters */
    chars(word,pos,letter) AS (
        SELECT word, 1, substr(word,1,1)
        FROM base
        UNION ALL
        SELECT word,
               pos + 1,
               substr(word, pos + 1, 1)
        FROM chars
        WHERE pos + 1 <= length(word)
    ),

    /* 3. build a canonical “sorted letters” signature for every word */
    signatures AS (
        SELECT word,
               (SELECT group_concat(letter, '')
                  FROM (SELECT letter
                        FROM chars c2
                        WHERE c2.word = c1.word
                        ORDER BY letter)
               ) AS sig
        FROM chars c1
        GROUP BY word
    ),

    /* 4. how many words share each signature (i.e., size of every anagram set) */
    sig_sizes AS (
        SELECT sig,
               COUNT(*) AS anagram_count
        FROM signatures
        GROUP BY sig
        HAVING COUNT(*) > 1               -- keep only signatures with ≥2 words
    ),

    /* 5. restrict to required words: start with 'r', 4–5 chars long, and in an anagram set */
    qualified AS (
        SELECT s.word,
               z.anagram_count
        FROM signatures  AS s
        JOIN sig_sizes   AS z ON s.sig = z.sig
        WHERE s.word GLOB 'r*'            -- case-sensitive ‘r…’
    )

/* 6. first 10 alphabetically */
SELECT word,
       anagram_count
FROM qualified
ORDER BY word
LIMIT 10;