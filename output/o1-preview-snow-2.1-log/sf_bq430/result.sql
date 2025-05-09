WITH eligible_activities AS (
    SELECT
        act."activity_id",
        act."assay_id",
        act."molregno",
        act."standard_type",
        act."standard_value",
        act."standard_relation",
        act."pchembl_value",
        act."doc_id",
        cp."heavy_atoms"
    FROM "EBI_CHEMBL"."EBI_CHEMBL"."ACTIVITIES" act
    JOIN "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_PROPERTIES" cp ON act."molregno" = cp."molregno"
    WHERE TRY_TO_DOUBLE(act."pchembl_value") > 10
      AND act."standard_value" IS NOT NULL
      AND TRY_TO_NUMBER(cp."heavy_atoms") BETWEEN 10 AND 15
),
eligible_assays AS (
    SELECT "assay_id"
    FROM eligible_activities
    GROUP BY "assay_id"
    HAVING COUNT(*) < 5
),
eligible_molregno_assays AS (
    SELECT "assay_id", "molregno"
    FROM eligible_activities
    GROUP BY "assay_id", "molregno"
    HAVING COUNT(*) < 2
),
filtered_activities AS (
    SELECT ea.*
    FROM eligible_activities ea
    JOIN eligible_assays ea1 ON ea."assay_id" = ea1."assay_id"
    JOIN eligible_molregno_assays ema ON ea."assay_id" = ema."assay_id" AND ea."molregno" = ema."molregno"
),
activity_pairs AS (
    SELECT
        fa1."activity_id" AS "activity_id_1",
        fa1."molregno" AS "molregno_1",
        fa1."assay_id" AS "assay_id",
        fa1."standard_type" AS "standard_type",
        fa1."standard_value" AS "standard_value_1",
        fa1."standard_relation" AS "standard_relation_1",
        fa1."pchembl_value" AS "pchembl_value_1",
        fa1."doc_id" AS "doc_id_1",
        fa1."heavy_atoms" AS "heavy_atoms_1",
        fa2."activity_id" AS "activity_id_2",
        fa2."molregno" AS "molregno_2",
        fa2."standard_value" AS "standard_value_2",
        fa2."standard_relation" AS "standard_relation_2",
        fa2."pchembl_value" AS "pchembl_value_2",
        fa2."doc_id" AS "doc_id_2",
        fa2."heavy_atoms" AS "heavy_atoms_2"
    FROM filtered_activities fa1
    JOIN filtered_activities fa2 ON fa1."assay_id" = fa2."assay_id"
        AND fa1."standard_type" = fa2."standard_type"
        AND fa1."molregno" < fa2."molregno"
),
molregno_smiles AS (
    SELECT "molregno", "canonical_smiles"
    FROM "EBI_CHEMBL"."EBI_CHEMBL"."COMPOUND_STRUCTURES"
    WHERE "canonical_smiles" IS NOT NULL
),
document_ranks AS (
    SELECT
        d."doc_id",
        d."journal",
        d."year",
        d."first_page",
        RANK() OVER (PARTITION BY d."journal", d."year" ORDER BY TRY_TO_NUMBER(d."first_page")) AS "doc_rank",
        COUNT(*) OVER (PARTITION BY d."journal", d."year") AS "total_docs"
    FROM "EBI_CHEMBL"."EBI_CHEMBL"."DOCS" d
    WHERE d."year" IS NOT NULL
),
document_dates AS (
    SELECT
        dr."doc_id",
        COALESCE(dr."year", '1970') AS "year_calculated",
        ROUND((dr."doc_rank" - 1)::FLOAT / NULLIF(dr."total_docs" - 1, 0), 4) AS "percent_rank",
        CASE
            WHEN dr."total_docs" = 1 THEN 1
            ELSE FLOOR(((dr."doc_rank" - 1)::FLOAT / (dr."total_docs" - 1)) * 11) + 1
        END AS "month_calculated",
        CASE
            WHEN dr."total_docs" = 1 THEN 1
            ELSE MOD(FLOOR(((dr."doc_rank" - 1)::FLOAT / (dr."total_docs" - 1)) * 308), 28) + 1
        END AS "day_calculated",
        TO_DATE(
            COALESCE(dr."year", '1970') || '-' ||
            TO_CHAR(CASE
                WHEN dr."total_docs" = 1 THEN 1
                ELSE FLOOR(((dr."doc_rank" - 1)::FLOAT / (dr."total_docs" - 1)) * 11) + 1
            END) || '-' ||
            TO_CHAR(CASE
                WHEN dr."total_docs" = 1 THEN 1
                ELSE MOD(FLOOR(((dr."doc_rank" - 1)::FLOAT / (dr."total_docs" - 1)) * 308), 28) + 1
            END),
            'YYYY-MM-DD'
        ) AS "publication_date"
    FROM document_ranks dr
)
SELECT
    GREATEST(TRY_TO_NUMBER(ap."heavy_atoms_1"), TRY_TO_NUMBER(ap."heavy_atoms_2")) AS "max_heavy_atom_count",
    GREATEST(dd1."publication_date", dd2."publication_date") AS "latest_publication_date",
    GREATEST(ap."doc_id_1", ap."doc_id_2") AS "highest_doc_id",
    CASE
        WHEN TRY_TO_DOUBLE(ap."standard_value_1") IS NOT NULL
            AND TRY_TO_DOUBLE(ap."standard_value_2") IS NOT NULL
            AND ap."standard_relation_1" IN ('=', '~', '<', '<<', '>', '>>')
            AND ap."standard_relation_2" IN ('=', '~', '<', '<<', '>', '>>') THEN
            CASE
                WHEN TRY_TO_DOUBLE(ap."standard_value_1") > TRY_TO_DOUBLE(ap."standard_value_2")
                    AND ap."standard_relation_1" IN ('>', '>>', '=')
                    AND ap."standard_relation_2" IN ('<', '<<', '=') THEN 'decrease'
                WHEN TRY_TO_DOUBLE(ap."standard_value_1") < TRY_TO_DOUBLE(ap."standard_value_2")
                    AND ap."standard_relation_1" IN ('<', '<<', '=')
                    AND ap."standard_relation_2" IN ('>', '>>', '=') THEN 'increase'
                WHEN TRY_TO_DOUBLE(ap."standard_value_1") = TRY_TO_DOUBLE(ap."standard_value_2")
                    AND ap."standard_relation_1" IN ('=', '~')
                    AND ap."standard_relation_2" IN ('=', '~') THEN 'no-change'
                ELSE 'unknown'
            END
        ELSE 'unknown'
    END AS "change_classification",
    LOWER(HEX_ENCODE(MD5(
        TO_JSON(OBJECT_CONSTRUCT(
            'activity_id_1', ap."activity_id_1",
            'activity_id_2', ap."activity_id_2",
            'canonical_smiles_1', ms1."canonical_smiles",
            'canonical_smiles_2', ms2."canonical_smiles"
        ))
    ))) AS "mmp_delta_uuid"
FROM activity_pairs ap
JOIN molregno_smiles ms1 ON ap."molregno_1" = ms1."molregno"
JOIN molregno_smiles ms2 ON ap."molregno_2" = ms2."molregno"
LEFT JOIN document_dates dd1 ON ap."doc_id_1" = dd1."doc_id"
LEFT JOIN document_dates dd2 ON ap."doc_id_2" = dd2."doc_id"
;