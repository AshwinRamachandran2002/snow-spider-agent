WITH seg AS (  -- 1.  KIRC allele‑specific segments on chr1
    SELECT
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
      AND "chromosome"        = 'chr1'
),
seg_cyto AS (  -- 2.  map every segment to overlapping cytobands + classify alteration
    SELECT
        c."cytoband_name",
        CASE
            WHEN s."copy_number" >= 4 THEN 'Amplification'
            WHEN s."copy_number"  = 3 THEN 'Gain'
            WHEN s."copy_number"  = 1 THEN 'HeterozygousDeletion'
        END                               AS "alteration_type"
    FROM seg               s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38" c
      ON c."chromosome" = s."chromosome"
     AND s."start_pos"  <= c."hg38_stop"
     AND s."end_pos"    >= c."hg38_start"
    WHERE s."copy_number" IN (1,3) OR s."copy_number" >= 4    -- keep only 3 classes
),
counts AS (   -- 3.  occurrences per cytoband & alteration class
    SELECT
        "cytoband_name",
        "alteration_type",
        COUNT(*) AS "cnt"
    FROM seg_cyto
    GROUP BY "cytoband_name", "alteration_type"
),
ranks AS (    -- 4.  rank cytobands within each alteration class
    SELECT
        "cytoband_name",
        "alteration_type",
        "cnt",
        RANK() OVER (PARTITION BY "alteration_type"
                     ORDER BY "cnt" DESC) AS "rk"
    FROM counts
),
pivoted AS (  -- 5.  put the three ranks side‑by‑side
    SELECT
        "cytoband_name",
        MAX(CASE WHEN "alteration_type" = 'Amplification'        THEN "rk" END) AS "rk_amp",
        MAX(CASE WHEN "alteration_type" = 'Gain'                 THEN "rk" END) AS "rk_gain",
        MAX(CASE WHEN "alteration_type" = 'HeterozygousDeletion' THEN "rk" END) AS "rk_hetdel"
    FROM ranks
    GROUP BY "cytoband_name"
)
-- 6.  cytobands whose three ranks are all within the top 11
SELECT
    "cytoband_name"
FROM pivoted
WHERE "rk_amp"    <= 11
  AND "rk_gain"   <= 11
  AND "rk_hetdel" <= 11
ORDER BY "cytoband_name";