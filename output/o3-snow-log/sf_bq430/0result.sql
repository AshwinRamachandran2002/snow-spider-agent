/* -----------------------------------------------------------
   Produce pairs of distinct molecules (10–15 heavy atoms) that
   satisfy the constraints described in the task.
------------------------------------------------------------*/
WITH
/* -----------------------------------------------------------------
   1.  Base set of qualifying activity rows (from ACTIVITIES_30).
----------------------------------------------------------------- */
activity_base AS (
    SELECT
        a."activity_id",
        a."assay_id",
        a."standard_type",
        a."standard_value",
        a."standard_relation",
        a."pchembl_value",
        a."doc_id",
        a."molregno",
        TO_NUMBER(cp."heavy_atoms")                       AS heavy_atoms,
        cs."canonical_smiles",
        d."journal"                                       AS journal,
        COALESCE(d."year", 1970)                          AS pub_year,
        TO_NUMBER(d."first_page")                         AS first_page
    FROM   "EBI_CHEMBL"."EBI_CHEMBL"."ACTIVITIES_30"          a
    JOIN   "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_PROPERTIES"    cp
               ON a."molregno" = cp."molregno"
    JOIN   "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_STRUCTURES_30" cs
               ON a."molregno" = cs."molregno"
    LEFT  JOIN "EBI_CHEMBL"."EBI_CHEMBL"."DOCS_29"            d
               ON a."doc_id" = d."doc_id"
    WHERE  TO_NUMBER(cp."heavy_atoms") BETWEEN 10 AND 15
      AND  a."pchembl_value"  > 10
      AND  a."standard_value" IS NOT NULL
      AND  a."standard_relation" = '='
      AND  a."potential_duplicate" = 0
),
/* -----------------------------------------------------------------
   2.  Keep only (assay_id , standard_type) combos with < 5 activities
----------------------------------------------------------------- */
assay_filter AS (
    SELECT "assay_id", "standard_type"
    FROM   activity_base
    GROUP  BY "assay_id", "standard_type"
    HAVING COUNT(*) < 5
),
qualified AS (
    SELECT b.*
    FROM   activity_base b
    JOIN   assay_filter f
           ON b."assay_id" = f."assay_id"
          AND b."standard_type" = f."standard_type"
),
/* -----------------------------------------------------------------
   3.  Synthetic publication date (year-month-day) per rules supplied.
----------------------------------------------------------------- */
date_calc AS (
    SELECT  q.*,
            PERCENT_RANK() OVER (
                PARTITION BY journal, pub_year
                ORDER BY first_page NULLS LAST
            )                                            AS pr,
            /* Month 1-12 */
            FLOOR(
                PERCENT_RANK() OVER (
                    PARTITION BY journal, pub_year
                    ORDER BY first_page NULLS LAST
                ) * 11
            ) + 1                                        AS month_num,
            /* Day 1-28  */
            MOD(
                FLOOR(
                    PERCENT_RANK() OVER (
                        PARTITION BY journal, pub_year
                        ORDER BY first_page NULLS LAST
                    ) * 308
                ),
                28
            ) + 1                                        AS day_num
    FROM   qualified q
),
activity_with_date AS (
    SELECT *,
           TO_VARCHAR(pub_year) || '-' ||
           LPAD(TO_VARCHAR(month_num),2,'0') || '-' ||
           LPAD(TO_VARCHAR(day_num)  ,2,'0')             AS pub_date
    FROM   date_calc
),
/* -----------------------------------------------------------------
   4.  Build unordered pairs within the same assay / standard_type.
----------------------------------------------------------------- */
pairs AS (
    SELECT
        a1."activity_id"                        AS act_id_1,
        a2."activity_id"                        AS act_id_2,
        a1."canonical_smiles"                   AS smiles_1,
        a2."canonical_smiles"                   AS smiles_2,
        a1."standard_value"                     AS std_val_1,
        a2."standard_value"                     AS std_val_2,
        a1.heavy_atoms                          AS heavy_1,
        a2.heavy_atoms                          AS heavy_2,
        GREATEST(a1.heavy_atoms, a2.heavy_atoms)            AS max_heavy_atoms,
        /* latest synthetic publication date in the pair */
        CASE WHEN a1.pub_date >= a2.pub_date
             THEN a1.pub_date ELSE a2.pub_date END         AS latest_pub_date,
        /* highest DOC_ID in the pair */
        GREATEST(a1."doc_id", a2."doc_id")                 AS highest_doc_id,
        /* change classification */
        CASE
            WHEN a1."standard_value" > a2."standard_value" THEN 'decrease'
            WHEN a1."standard_value" < a2."standard_value" THEN 'increase'
            ELSE                                             'no-change'
        END                                                AS change_class,
        /* UUID derived from activity IDs */
        HEX_ENCODE(
            MD5(
                TO_JSON(
                    OBJECT_CONSTRUCT('A', a1."activity_id",
                                     'B', a2."activity_id")
                )
            )
        )                                                  AS uuid_activity_ids,
        /* UUID derived from canonical SMILES */
        HEX_ENCODE(
            MD5(
                TO_JSON(
                    OBJECT_CONSTRUCT('A', a1."canonical_smiles",
                                     'B', a2."canonical_smiles")
                )
            )
        )                                                  AS uuid_smiles
    FROM   activity_with_date a1
    JOIN   activity_with_date a2
           ON  a1."assay_id"      = a2."assay_id"
           AND a1."standard_type" = a2."standard_type"
           AND a1."molregno"     <> a2."molregno"
           AND a1."activity_id"   < a2."activity_id"   -- ensures unique pair
)
/* -----------------------------------------------------------------
   5.  Final result
----------------------------------------------------------------- */
SELECT *
FROM   pairs
LIMIT 100;