WITH
-- 1) TCGA‑KIRC allelic copy‑number segments on chromosome 1 and their alteration category
seg AS (
    SELECT
        s."chromosome",
        s."start_pos",
        s."end_pos",
        CASE
            WHEN s."copy_number" > 3 THEN 'Amplification'
            WHEN s."copy_number" = 3 THEN 'Gain'
            WHEN s."copy_number" = 1 THEN 'Heterozygous Deletion'
            ELSE 'Other'
        END                                                AS "category"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    WHERE s."project_short_name" = 'TCGA-KIRC'
      AND s."chromosome" = 'chr1'
      AND s."copy_number" IN (1,3,4,5,6,7,8,9,10)         -- keep only relevant CN states
),
-- 2) Cytobands for chromosome 1 (hg38)
band AS (
    SELECT
        b."chromosome",
        b."hg38_start",
        b."hg38_stop",
        b."cytoband_name"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38" b
    WHERE b."chromosome" = 'chr1'
),
-- 3) Count of segment overlaps per cytoband and alteration category
cnt AS (
    SELECT
        b."cytoband_name",
        s."category",
        COUNT(*)                                            AS "segment_count"
    FROM seg s
    JOIN band b
      ON s."start_pos" <= b."hg38_stop"
     AND s."end_pos"   >= b."hg38_start"
    GROUP BY b."cytoband_name", s."category"
),
-- 4) Rank cytobands within each category by frequency (higher count → higher rank)
ranked AS (
    SELECT
        c."cytoband_name",
        c."category",
        c."segment_count",
        RANK() OVER (PARTITION BY c."category"
                     ORDER BY c."segment_count" DESC NULLS LAST) AS "rk"
    FROM cnt c
),
-- 5) Collect ranks for the three requested alteration types
ranks_per_band AS (
    SELECT
        r."cytoband_name",
        MAX(CASE WHEN r."category" = 'Amplification'        THEN r."rk" END) AS "amp_rk",
        MAX(CASE WHEN r."category" = 'Gain'                 THEN r."rk" END) AS "gain_rk",
        MAX(CASE WHEN r."category" = 'Heterozygous Deletion' THEN r."rk" END) AS "het_rk"
    FROM ranked r
    GROUP BY r."cytoband_name"
)
-- 6) Final selection: cytobands ranking within top‑11 for all three categories
SELECT
    "cytoband_name"
FROM ranks_per_band
WHERE "amp_rk"  <= 11
  AND "gain_rk" <= 11
  AND "het_rk"  <= 11
ORDER BY "cytoband_name";