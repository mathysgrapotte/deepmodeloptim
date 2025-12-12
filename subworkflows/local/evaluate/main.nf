/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STIMULUS_EVALUATE } from '../../../modules/local/stimulus/evaluate'
include { COLLECT_METRICS   } from '../../../modules/local/stimulus/collect_metrics'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow EVALUATE_WF {
    take:
    ch_model_tmp           // from TUNE_WF.out.model_tmp: [meta, model, config, weights]
    ch_transformed_data    // [meta, data_path]
    ch_transform_config    // [meta, config_path] - transform YAML config (meta.id is config id, not data id)

    main:

    ch_versions = Channel.empty()

    // Join model outputs with transformed data by matching id, split_id, transform_id
    // Note: ch_transform_config has different meta.id (config file id), so we join only by transform_id
    ch_eval_input = ch_model_tmp
        .map { meta, model, config, weights ->
            def key = [meta.id, meta.split_id, meta.transform_id]
            [key, meta, model, config, weights]
        }
        .combine(
            ch_transformed_data.map { meta, data ->
                def key = [meta.id, meta.split_id, meta.transform_id]
                [key, data]
            },
            by: 0
        )
        .map { key, meta, model, model_config, weights, data ->
            // key is [id, split_id, transform_id], we need transform_id for config join
            def transform_key = meta.transform_id
            [transform_key, meta, model, model_config, weights, data]
        }
        .combine(
            ch_transform_config.map { meta, config ->
                // Join only by transform_id since config's meta.id is different from data's meta.id
                def transform_key = meta.transform_id
                [transform_key, config]
            },
            by: 0
        )
        .map { transform_key, meta, model, model_config, weights, data, transform_config ->
            [[meta, model, model_config, weights], [meta, data], [meta, transform_config]]
        }

    STIMULUS_EVALUATE(
        ch_eval_input.map { it[0] },
        ch_eval_input.map { it[1] },
        ch_eval_input.map { it[2] }
    )

    ch_versions = ch_versions.mix(STIMULUS_EVALUATE.out.versions)

    // Collect all metrics into single CSV
    ch_all_metrics = STIMULUS_EVALUATE.out.metrics
        .map { meta, csv -> csv }
        .collect()

    COLLECT_METRICS(ch_all_metrics)

    emit:
    metrics = STIMULUS_EVALUATE.out.metrics
    combined_metrics = COLLECT_METRICS.out.combined
    versions = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
