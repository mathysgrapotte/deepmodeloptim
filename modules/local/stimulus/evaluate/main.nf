process STIMULUS_EVALUATE {
    tag "${meta.id}"
    label 'process_medium'
    container "docker.io/mathysgrapotte/stimulus-py:dev"

    input:
    tuple val(meta), path(model), path(model_config), path(model_weight)
    tuple val(meta2), path(transformed_data)
    tuple val(meta3), path(transform_config)

    output:
    tuple val(meta), path("${prefix}-metrics.csv"), emit: metrics
    path "versions.yml", emit: versions

    script:
    prefix = task.ext.prefix ?: "${meta.id}-split-${meta.split_id}-trans-${meta.transform_id}-rep-${meta.replicate}"
    def args = task.ext.args ?: ""
    """
    stimulus evaluate \\
        -d ${transformed_data} \\
        -m ${model} \\
        -c ${model_config} \\
        -w ${model_weight} \\
        -t ${transform_config} \\
        -o ${prefix}-metrics.csv \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stimulus: \$(stimulus -v | cut -d ' ' -f 3)
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}-split-${meta.split_id}-trans-${meta.transform_id}-rep-${meta.replicate}"
    """
    echo "transforms.transformation_name,global_params.seed,metric_loss,metric_accuracy" > ${prefix}-metrics.csv
    echo "${meta.transform_id},42,0.0,0.0" >> ${prefix}-metrics.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        stimulus: \$(stimulus -v | cut -d ' ' -f 3)
    END_VERSIONS
    """
}
