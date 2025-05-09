/*  Chi-square statistic for association between histological type and
    CDH1-mutation status in BRCA patients (PanCancer Atlas).

    – keeps only participants with a known histological type
    – considers reliable mutations (FILTER = 'PASS')
    – excludes histological types or mutation categories whose
      marginal totals ≤ 10 before computing the statistic
*/
WITH mutated_patients AS (         -- reliable CDH1-mutated BRCA participants
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"        = 'BRCA'
      AND "Hugo_Symbol"  = 'CDH1'
      AND "FILTER"       = 'PASS'
),
patient_status AS (               -- one record per BRCA participant
    SELECT
        c."histological_type",
        CASE
            WHEN m."ParticipantBarcode" IS NOT NULL THEN 'Mutated'
            ELSE 'Wildtype'
        END                           AS "mutation_status"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    LEFT JOIN mutated_patients m
           ON m."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE c."acronym"          = 'BRCA'
      AND c."histological_type" IS NOT NULL
),
contingency AS (                  -- raw 2-way counts
    SELECT
        "histological_type",
        "mutation_status",
        COUNT(*)                  AS "obs"
    FROM patient_status
    GROUP BY "histological_type", "mutation_status"
),
row_tot AS (                      -- row marginals
    SELECT "histological_type", SUM("obs") AS "row_total"
    FROM contingency
    GROUP BY "histological_type"
),
col_tot AS (                      -- column marginals
    SELECT "mutation_status", SUM("obs") AS "col_total"
    FROM contingency
    GROUP BY "mutation_status"
),
filtered AS (                     -- keep rows/cols with all marginals > 10
    SELECT c.*
    FROM   contingency c
    JOIN   row_tot r  ON r."histological_type" = c."histological_type"
    JOIN   col_tot k  ON k."mutation_status"   = c."mutation_status"
    WHERE  r."row_total"  > 10
      AND  k."col_total"  > 10
),
row_tot_f AS (                    -- row totals after filtering
    SELECT "histological_type", SUM("obs") AS "row_total"
    FROM filtered
    GROUP BY "histological_type"
),
col_tot_f AS (                    -- column totals after filtering
    SELECT "mutation_status", SUM("obs") AS "col_total"
    FROM filtered
    GROUP BY "mutation_status"
),
grand_tot AS (                    -- grand total
    SELECT SUM("obs") AS "grand_total" FROM filtered
),
chi_components AS (               -- per-cell χ² contribution
    SELECT
        f."histological_type",
        f."mutation_status",
        f."obs"                                         AS "observed",
        (r."row_total" * k."col_total") / g."grand_total"::FLOAT
                                                      AS "expected",
        POWER(
              f."obs" - (r."row_total" * k."col_total") / g."grand_total"::FLOAT,
              2
        ) / ((r."row_total" * k."col_total") / g."grand_total"::FLOAT)
                                                      AS "chi_piece"
    FROM   filtered     f
    JOIN   row_tot_f    r ON r."histological_type" = f."histological_type"
    JOIN   col_tot_f    k ON k."mutation_status"   = f."mutation_status"
    JOIN   grand_tot    g
)
SELECT ROUND(SUM("chi_piece"),4) AS "chi_square_value"
FROM   chi_components;