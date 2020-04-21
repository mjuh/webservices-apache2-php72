buildWebService(
    publishOnInternet: true,
    testHook: {
        build (job: "../../apps/bitrix-start/master",
               parameters: [[$class: "BooleanParameterValue",
                             name: "DEPLOY",
                             value: false],
                            [$class: "StringParameterValue",
                             name: "UPSTREAM_BRANCH_NAME",
                             value: env.GIT_BRANCH]])
    })
