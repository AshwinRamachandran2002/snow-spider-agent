WITH clinical_br AS (
    -- BRCA patients with a known histologic subtype
    SELECT
        "bcr_patient_barcode"    AS "ParticipantBarcode",
        "histological_type"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE "acronym" = 'BRCA'
      AND "histological_type" IS NOT NULL
), 

cdh1_mut AS (
    -- Reliable (FILTER = 'PASS') CDH1 mutations in BRCA
    SELECT DISTINCT
        "ParticipantBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'BRCA'
      AND "Hugo_Symbol" = 'CDH1'
      AND UPPER("FILTER") = 'PASS'
), 

combined AS (
    -- Assign mutation status per patient
    SELECT
        c."histological_type",
        CASE 
            WHEN m."ParticipantBarcode" IS NOT NULL THEN 'Mutated'
            ELSE 'WildType'
        END                                            AS "mutation_status"
    FROM clinical_br c
    LEFT JOIN cdh1_mut m
           ON c."ParticipantBarcode" = m."ParticipantBarcode"
), 

contingency AS (
    -- Observed counts for each (histology × mutation_status) cell
    SELECT
        "histological_type",
        "mutation_status",
        COUNT(*)                                      AS "obs_count"
    FROM combined
    GROUP BY "histological_type", "mutation_status"
), 

contingency_filtered AS (
    -- Add marginal & grand totals, keep only rows/cols with totals > 10
    SELECT
        c.*,
        SUM("obs_count") OVER (PARTITION BY "histological_type")          AS "row_total",
        SUM("obs_count") OVER (PARTITION BY "mutation_status")            AS "col_total",
        SUM("obs_count") OVER ()                                          AS "grand_total"
    FROM contingency c
), 

valid AS (
    -- Expected counts for valid cells
    SELECT
        "histological_type",
        "mutation_status",
        "obs_count",
        "row_total",
        "col_total",
        "grand_total",
        ("row_total" * "col_total") / "grand_total"::FLOAT               AS "exp_count"
    FROM contingency_filtered
    WHERE "row_total" > 10
      AND "col_total" > 10
)

-- Chi‑square statistic
SELECT
    SUM( POWER("obs_count" - "exp_count", 2) / "exp_count" )             AS "chi_square_value"
FROM valid;