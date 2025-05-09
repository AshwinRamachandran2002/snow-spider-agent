WITH winner AS (
    /* 1. For every (problem, version, step) keep the best Stack and non-Stack scores */
    SELECT   ms."name",
             ms."version",
             ms."step",
             MAX(CASE WHEN ms."model" LIKE '%Stack%' THEN ms."test_score" END) AS stack_best,
             MAX(CASE WHEN ms."model" NOT LIKE '%Stack%' THEN ms."test_score" END) AS non_stack_best
    FROM     "model_score" AS ms
    WHERE    ms."step" IN (1, 2, 3)
    GROUP BY ms."name", ms."version", ms."step"
    HAVING   stack_best IS NOT NULL
       AND   (non_stack_best IS NULL OR stack_best > non_stack_best)   -- Stack strictly better
),
stack_wins AS (
    /* 2. Count superior Stack steps per problem */
    SELECT   "name",
             COUNT(*) AS nb_superior_steps
    FROM     winner
    GROUP BY "name"
),
solution_rows AS (
    /* 3. Count how many rows each problem has in the solution table */
    SELECT   "name",
             COUNT(*) AS nb_solution_rows
    FROM     "solution"
    GROUP BY "name"
)
SELECT sw."name"
FROM   stack_wins   AS sw
JOIN   solution_rows AS sr USING ("name")
WHERE  sw.nb_superior_steps > sr.nb_solution_rows;