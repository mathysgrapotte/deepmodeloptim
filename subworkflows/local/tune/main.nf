/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { STIMULUS_TUNE              } from '../../../modules/local/stimulus/tune'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN SUBWORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow TUNE_WF {
    take:
    ch_transformed_data
    ch_model
    ch_model_config
    ch_initial_weights
    tune_trials_range
    tune_replicates

    main:

    // Split the tune_trials_range into individual trials
    ch_versions = Channel.empty()


    // ch_model_config = CUSTOM_MODIFY_MODEL_CONFIG.out.config
    // We assume the model config already contains what we need or is just passed through.
    // If n_trials needs to be injected, it should be done upstream or handled by STIMULUS_TUNE if supported or acceptable to be static.
    // Based on requirements, we are removing the custom modification step.
    
    // Pass original config through
    // ch_model_config is already a channel of paths from input

    // ch_input = ch_split_data
    //     .combine(ch_config_transform, by: [])
    //     .map { meta_data, data, meta_config, config ->
    //         def meta = meta_data + [transform_id: meta_config.transform_id]
    //         [
    //             data: [meta, data],
    //             config: [meta, config]
    //         ]
    //     }
    //     .multiMap { item ->
    //         data: item.data
    //         config: item.config
    //     }

    // ch_transformed_data.view()
    ch_tune_input = ch_transformed_data
        .combine(ch_model.map{it[1]})
        .combine(ch_model_config.map{it[1]})
        .combine(ch_initial_weights)    // when initial_weights is empty .map{it[1]} will return [], and not properly combined
        .combine(tune_replicates)
        .multiMap { meta, data, model, model_config, meta_weights, initial_weights, n_replicate ->
            // Assuming we don't need n_trials in meta anymore or get it differently.
            // If it was only added by CUSTOM_MODIFY_MODEL_CONFIG, we remove it from here.
            def meta_new = meta + [replicate: n_replicate] 
            data:
                [meta_new, data]
            model:
                [meta_new, model, model_config, initial_weights]
        }
    // Print optuna-dashboard command if storage was configured
    if (params.optuna_storage) {
        log.info ""
        log.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log.info "  Optuna Dashboard - Real-time Visualization"
        log.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log.info "  To monitor tuning progress in real-time, run in a separate terminal:"
        log.info ""
        log.info "    optuna-dashboard ${params.optuna_storage}"
        log.info ""
        log.info "  Then open http://127.0.0.1:8080 in your browser."
        log.info "  Study name: ${params.optuna_study_name ?: 'auto-generated'}"
        log.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log.info ""
    }

    // run stimulus tune
    STIMULUS_TUNE(
        ch_tune_input.data,
        ch_tune_input.model
    )

    ch_versions = ch_versions.mix(STIMULUS_TUNE.out.versions)

    // parse output for evaluation block

    emit:
    best_model = STIMULUS_TUNE.out.model
    optimizer = STIMULUS_TUNE.out.optimizer
    tune_experiments = STIMULUS_TUNE.out.artifacts
    journal = STIMULUS_TUNE.out.journal
    versions = ch_versions // channel: [ versions.yml ]
    // these are temporaly needed for predict, it will be changed in the future!
    model_tmp = STIMULUS_TUNE.out.model_tmp
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
