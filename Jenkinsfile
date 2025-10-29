def buildAndPush(String serviceName, String buildNumber, String ecrRegistry, String ecrRepoName) {
    echo "Building and pushing service: ${serviceName}"
    def imageNameWithTag = "${ecrRegistry}/${ecrRepoName}:${serviceName}-${buildNumber}"
    dir(serviceName) {
        sh "docker build -t ${imageNameWithTag} ."
    }
    sh "docker push ${imageNameWithTag}"
}

def buildAndPushAll(String buildNumber, String ecrRegistry, String ecrRepoName) {
    def allServices = ['vote', 'result', 'worker'] 
    parallel allServices.collectEntries { svc ->
        ["Building ${svc}": { buildAndPush(svc, buildNumber, ecrRegistry, ecrRepoName) }]
    }
}

pipeline {
    agent any

    parameters {
        choice(
            name: 'SERVICE_NAME',
            choices: ['vote', 'result', 'worker', 'ALL'],
            description: 'Select the service image to build and push'
        )
    }
    
    environment {
        AWS_REGION        = 'ap-southeast-1'
        AWS_ACCOUNT_ID    = '332305705434'
        ECR_REPO_NAME     = 'voting-app' 
        
        GITOPS_REPO_USER  = 'Quackusarle'
        GITOPS_REPO_NAME  = 'example-voting-app'
        GITOPS_REPO_BRANCH = 'main'

        ECR_REGISTRY      = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        credentialsId: 'github-pat',
                        url: "https://github.com/${GITOPS_REPO_USER}/${GITOPS_REPO_NAME}.git"
                    ]]
                ])
            }
        }
        
        stage('Build and Push to ECR') {
            steps {
                script {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    if (params.SERVICE_NAME == 'ALL') {
                        buildAndPushAll(BUILD_NUMBER, ECR_REGISTRY, ECR_REPO_NAME)
                    } else {
                        buildAndPush(params.SERVICE_NAME, BUILD_NUMBER, ECR_REGISTRY, ECR_REPO_NAME)
                    }
                }
            }
        }
        
        stage('Update Helm Values (GitOps Trigger)') {
            when {
                expression { params.SERVICE_NAME != 'ALL' }
            }
            steps {
                script {
                    sh 'git config --global user.email "jenkins-ci@bot.com"'
                    sh 'git config --global user.name "Jenkins CI Bot"'

                    def valuesFile = "voting-app-chart/values.yaml"
                    def newTag = "${params.SERVICE_NAME}-${BUILD_NUMBER}"
                    
                    echo "Updating ${valuesFile} for service '${params.SERVICE_NAME}' with new tag: ${newTag}"
                    
                    sh "sed -i -e '/^${params.SERVICE_NAME}:/,/^[a-zA-Z]/{s/  tag: .*/  tag: \"${newTag}\"/}' ${valuesFile}"

                    sh "git add ${valuesFile}"
                    sh "git diff-index --quiet HEAD || git commit -m 'CI: Update Helm tag for ${params.SERVICE_NAME} to ${newTag}'"
                    sh "git push origin HEAD:${GITOPS_REPO_BRANCH}"
                }
            }
        }
    }
}