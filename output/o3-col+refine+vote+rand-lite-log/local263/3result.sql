WITH score_cmp AS (               -- 1. compare “Stack” vs. non-Stack per data set / version
    SELECT  "name",
            "version",
            MAX(CASE WHEN "model" NOT LIKE '%Stack%' THEN "test_score" END) AS max_non_stack,
            MAX(CASE WHEN "model"  LIKE '%Stack%' THEN "test_score" END)   AS stack_score
    FROM    "model_score"
    GROUP BY "name","version"
),
status_tag AS (                   -- 2. label each (name,version) as strong / soft
    SELECT  "name","version",
            CASE WHEN stack_score >  max_non_stack THEN 'strong'
                 WHEN stack_score = max_non_stack THEN 'soft'
            END AS status
    FROM    score_cmp
    WHERE   stack_score IS NOT NULL
      AND   max_non_stack IS NOT NULL
),
l1_by_ds AS (                      -- 3. bring in the L1_model (one row per distinct L1_model)
    SELECT  st.status,
            m."L1_model"
    FROM    status_tag  st
    JOIN    "model"     m
           ON m."name"    = st."name"
          AND m."version" = st."version"
    GROUP BY st.status, m."name", m."version", m."L1_model"
),
cnt AS (                           -- 4. count how often each L1_model appears per status
    SELECT  status,
            "L1_model",
            COUNT(*) AS n_occurrences
    FROM    l1_by_ds
    GROUP BY status, "L1_model"
),
ranked AS (                        -- 5. keep the most frequent L1_model for every status
    SELECT  c.*,
            ROW_NUMBER() OVER (PARTITION BY status
                               ORDER BY n_occurrences DESC, "L1_model") AS rn
    FROM    cnt c
)
SELECT  status,
        "L1_model",
        n_occurrences
FROM    ranked
WHERE   rn = 1
ORDER BY status;