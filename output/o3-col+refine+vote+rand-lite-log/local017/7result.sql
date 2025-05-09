WITH ranked AS (
    /* rank causes by frequency within each year */
    SELECT
        ci."db_year",
        c."primary_collision_factor",
        COUNT(*) AS cnt,
        ROW_NUMBER() OVER (
            PARTITION BY ci."db_year"
            ORDER BY COUNT(*) DESC
        ) AS rk
    FROM "collisions" AS c
    JOIN "case_ids"  AS ci
      ON ci."case_id" = c."case_id"
    GROUP BY ci."db_year", c."primary_collision_factor"
),
top2 AS (
    /* keep only the two most frequent causes for every year */
    SELECT
        db_year,
        primary_collision_factor
    FROM ranked
    WHERE rk <= 2
),
pair_per_year AS (
    /* build a single string with the two leading causes per year */
    SELECT
        db_year,
        GROUP_CONCAT(primary_collision_factor, ', ') AS top_two_causes
    FROM (
        SELECT
            db_year,
            primary_collision_factor
        FROM top2
        ORDER BY db_year, primary_collision_factor        -- stable order
    )
    GROUP BY db_year
),
pair_freq AS (
    /* how many years have each particular pair? */
    SELECT
        top_two_causes,
        COUNT(*) AS yrs
    FROM pair_per_year
    GROUP BY top_two_causes
),
unique_years AS (
    /* years whose top-two-cause pair is unique */
    SELECT
        p.db_year
    FROM pair_per_year AS p
    JOIN pair_freq      AS f
          ON f.top_two_causes = p.top_two_causes
    WHERE f.yrs = 1
)
SELECT COALESCE(CAST(db_year AS TEXT), 'None') AS db_year
FROM (
    /* deliver the unique year(s); if none, return the word 'None' */
    SELECT db_year FROM unique_years
    UNION ALL
    SELECT NULL
    WHERE NOT EXISTS (SELECT 1 FROM unique_years)
);