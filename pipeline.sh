#!/bin/bash

source config.sh

declare -A pipelines=(
    ["grafana"]="git@github.com:RootSasha/grafana.git"
    ["site"]="git@github.com:RootSasha/diplome-site.git"
)

# Створення або оновлення джобів Jenkins
for job in "${!pipelines[@]}"; do
    REPO_URL="${pipelines[$job]}"
    JOB_XML="$JOB_DIR/$job.xml"

    echo "Створюємо пайплайн: $job (джерело: $REPO_URL)..."

    mkdir -p "$JOB_DIR"
    cat > "$JOB_XML" <<EOF
<flow-definition plugin="workflow-job">
        <actions/>
        <description>Pipeline для $job</description>
        <keepDependencies>false</keepDependencies>
        <properties/>
        <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition">
                <scm class="hudson.plugins.git.GitSCM">
                        <configVersion>2</configVersion>
                        <userRemoteConfigs>
                                <hudson.plugins.git.UserRemoteConfig>
                                        <url>$REPO_URL</url>
                                        <credentialsId>$CREDENTIAL_ID</credentialsId>
                                </hudson.plugins.git.UserRemoteConfig>
                        </userRemoteConfigs>
                        <branches>
                                <hudson.plugins.git.BranchSpec>
                                        <name>*/main</name>
                                </hudson.plugins.git.BranchSpec>
                        </branches>
                </scm>
                <scriptPath>Jenkinsfile</scriptPath>
                <sandbox>true</sandbox>
        </definition>
        <triggers/>
</flow-definition>
EOF

    java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASSWORD" create-job "$job" < "$JOB_XML"

    if [[ $? -eq 0 ]]; then
        echo "✅ $job створено успішно!"
    else
        echo "❌ Помилка створення $job, пробуємо оновити..."
        java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASSWORD" update-job "$job" < "$JOB_XML"
        if [[ $? -eq 0 ]]; then
            echo "✅ $job оновлено успішно!"
        else
            echo "❌ Помилка оновлення $job"
        fi
    fi
done

echo "✅ Всі пайплайни створено!"
