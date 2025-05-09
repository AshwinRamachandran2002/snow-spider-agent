WITH base AS (
    SELECT *
    FROM "IDC"."IDC_V17"."DICOM_ALL"
    WHERE "collection_id" IN ('tcga_luad', 'tcga_lusc')
      AND "Modality" = 'SM'
      AND (   "ImageType" ILIKE '%VOLUME%'
           OR "FrameType" ILIKE '%VOLUME%' )
      AND "TransferSyntaxUID" IN ( '1.2.840.10008.1.2.4.50',   -- JPEG baseline
                                   '1.2.840.10008.1.2.4.70',   -- JPEG lossless
                                   '1.2.840.10008.1.2.4.90',   -- JPEG‑LS
                                   '1.2.840.10008.1.2.4.91',   -- JPEG‑LS lossless
                                   '1.2.840.10008.1.2.4.95')   -- JPEG‑2000
),
specimen_flags AS (
    SELECT
        b."PatientID"                                            AS patient_id,
        b."collection_id"                                        AS collection_id,
        CASE
             WHEN b."TransferSyntaxUID" = '1.2.840.10008.1.2.4.95' THEN 'jpeg2000'
             ELSE 'jpeg'
        END                                                      AS compression_type,
        MAX(CASE WHEN f.value::STRING ILIKE '%freezing%medium%' THEN 1 ELSE 0 END)  AS has_freezing_medium,
        MAX(CASE WHEN f.value::STRING ILIKE '%17621005%'        THEN 1 ELSE 0 END)  AS has_normal_code,
        MAX(CASE WHEN f.value::STRING ILIKE '%86049000%'        THEN 1 ELSE 0 END)  AS has_tumor_code,
        MIN(b."SOPInstanceUID")                                  AS any_instance     -- ensures deterministic ordering
    FROM   base b,
           LATERAL FLATTEN(input => b."SpecimenDescriptionSequence") f
    GROUP  BY patient_id, collection_id, compression_type
)
SELECT
    patient_id                             AS subject_id,
    collection_id                          AS collection,
    'SM'                                   AS modality,
    'VOLUME'                               AS image_type,
    compression_type                       AS compression,
    'Tissue freezing medium'               AS embedding_medium,
    CASE
         WHEN has_normal_code = 1 THEN 'normal'
         ELSE 'tumor'
    END                                    AS tissue_type,
    CASE
         WHEN collection_id = 'tcga_luad' THEN 'luad'
         ELSE 'lscc'
    END                                    AS cancer_subtype
FROM   specimen_flags
WHERE  has_freezing_medium = 1
  AND (has_normal_code = 1 OR has_tumor_code = 1)
ORDER BY any_instance ASC;